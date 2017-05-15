//===- ScopBuilder.cpp ---------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Create a polyhedral description for a static control flow region.
//
// The pass creates a polyhedral description of the Scops detected by the SCoP
// detection derived from their LLVM-IR code.
//
//===----------------------------------------------------------------------===//

#include "polly/ScopBuilder.h"
#include "polly/Options.h"
#include "polly/Support/GICHelper.h"
#include "polly/Support/SCEVValidator.h"
#include "polly/Support/VirtualInstruction.h"
#include "llvm/Analysis/RegionIterator.h"
#include "llvm/IR/DiagnosticInfo.h"

using namespace llvm;
using namespace polly;

#define DEBUG_TYPE "polly-scops"

STATISTIC(ScopFound, "Number of valid Scops");
STATISTIC(RichScopFound, "Number of Scops containing a loop");
STATISTIC(InfeasibleScops,
          "Number of SCoPs with statically infeasible context.");

static cl::opt<bool> ModelReadOnlyScalars(
    "polly-analyze-read-only-scalars",
    cl::desc("Model read-only scalar values in the scop description"),
    cl::Hidden, cl::ZeroOrMore, cl::init(true), cl::cat(PollyCategory));

static cl::opt<bool> UnprofitableScalarAccs(
    "polly-unprofitable-scalar-accs",
    cl::desc("Count statements with scalar accesses as not optimizable"),
    cl::Hidden, cl::init(false), cl::cat(PollyCategory));

static cl::opt<bool> DetectFortranArrays(
    "polly-detect-fortran-arrays",
    cl::desc("Detect Fortran arrays and use this for code generation"),
    cl::Hidden, cl::init(false), cl::cat(PollyCategory));

void ScopBuilder::buildPHIAccesses(PHINode *PHI, Region *NonAffineSubRegion,
                                   bool IsExitBlock) {

  // PHI nodes that are in the exit block of the region, hence if IsExitBlock is
  // true, are not modeled as ordinary PHI nodes as they are not part of the
  // region. However, we model the operands in the predecessor blocks that are
  // part of the region as regular scalar accesses.

  // If we can synthesize a PHI we can skip it, however only if it is in
  // the region. If it is not it can only be in the exit block of the region.
  // In this case we model the operands but not the PHI itself.
  auto *Scope = LI.getLoopFor(PHI->getParent());
  if (!IsExitBlock && canSynthesize(PHI, *scop, &SE, Scope))
    return;

  // PHI nodes are modeled as if they had been demoted prior to the SCoP
  // detection. Hence, the PHI is a load of a new memory location in which the
  // incoming value was written at the end of the incoming basic block.
  bool OnlyNonAffineSubRegionOperands = true;
  for (unsigned u = 0; u < PHI->getNumIncomingValues(); u++) {
    Value *Op = PHI->getIncomingValue(u);
    BasicBlock *OpBB = PHI->getIncomingBlock(u);

    // Do not build PHI dependences inside a non-affine subregion, but make
    // sure that the necessary scalar values are still made available.
    if (NonAffineSubRegion && NonAffineSubRegion->contains(OpBB)) {
      auto *OpInst = dyn_cast<Instruction>(Op);
      if (!OpInst || !NonAffineSubRegion->contains(OpInst))
        ensureValueRead(Op, OpBB);
      continue;
    }

    OnlyNonAffineSubRegionOperands = false;
    ensurePHIWrite(PHI, OpBB, Op, IsExitBlock);
  }

  if (!OnlyNonAffineSubRegionOperands && !IsExitBlock) {
    addPHIReadAccess(PHI);
  }
}

void ScopBuilder::buildScalarDependences(Instruction *Inst) {
  assert(!isa<PHINode>(Inst));

  // Pull-in required operands.
  for (Use &Op : Inst->operands())
    ensureValueRead(Op.get(), Inst->getParent());
}

void ScopBuilder::buildEscapingDependences(Instruction *Inst) {
  // Check for uses of this instruction outside the scop. Because we do not
  // iterate over such instructions and therefore did not "ensure" the existence
  // of a write, we must determine such use here.
  for (Use &U : Inst->uses()) {
    Instruction *UI = dyn_cast<Instruction>(U.getUser());
    if (!UI)
      continue;

    BasicBlock *UseParent = getUseBlock(U);
    BasicBlock *UserParent = UI->getParent();

    // An escaping value is either used by an instruction not within the scop,
    // or (when the scop region's exit needs to be simplified) by a PHI in the
    // scop's exit block. This is because region simplification before code
    // generation inserts new basic blocks before the PHI such that its incoming
    // blocks are not in the scop anymore.
    if (!scop->contains(UseParent) ||
        (isa<PHINode>(UI) && scop->isExit(UserParent) &&
         scop->hasSingleExitEdge())) {
      // At least one escaping use found.
      ensureValueWrite(Inst);
      break;
    }
  }
}

/// Check that a value is a Fortran Array descriptor.
///
/// We check if V has the following structure:
/// %"struct.array1_real(kind=8)" = type { i8*, i<zz>, i<zz>,
///                                   [<num> x %struct.descriptor_dimension] }
///
///
/// %struct.descriptor_dimension = type { i<zz>, i<zz>, i<zz> }
///
/// 1. V's type name starts with "struct.array"
/// 2. V's type has layout as shown.
/// 3. Final member of V's type has name "struct.descriptor_dimension",
/// 4. "struct.descriptor_dimension" has layout as shown.
/// 5. Consistent use of i<zz> where <zz> is some fixed integer number.
///
/// We are interested in such types since this is the code that dragonegg
/// generates for Fortran array descriptors.
///
/// @param V the Value to be checked.
///
/// @returns True if V is a Fortran array descriptor, False otherwise.
bool isFortranArrayDescriptor(Value *V) {
  PointerType *PTy = dyn_cast<PointerType>(V->getType());

  if (!PTy)
    return false;

  Type *Ty = PTy->getElementType();
  assert(Ty && "Ty expected to be initialized");
  auto *StructArrTy = dyn_cast<StructType>(Ty);

  if (!(StructArrTy && StructArrTy->hasName()))
    return false;

  if (!StructArrTy->getName().startswith("struct.array"))
    return false;

  if (StructArrTy->getNumElements() != 4)
    return false;

  const ArrayRef<Type *> ArrMemberTys = StructArrTy->elements();

  // i8* match
  if (ArrMemberTys[0] != Type::getInt8PtrTy(V->getContext()))
    return false;

  // Get a reference to the int type and check that all the members
  // share the same int type
  Type *IntTy = ArrMemberTys[1];
  if (ArrMemberTys[2] != IntTy)
    return false;

  // type: [<num> x %struct.descriptor_dimension]
  ArrayType *DescriptorDimArrayTy = dyn_cast<ArrayType>(ArrMemberTys[3]);
  if (!DescriptorDimArrayTy)
    return false;

  // type: %struct.descriptor_dimension := type { ixx, ixx, ixx }
  StructType *DescriptorDimTy =
      dyn_cast<StructType>(DescriptorDimArrayTy->getElementType());

  if (!(DescriptorDimTy && DescriptorDimTy->hasName()))
    return false;

  if (DescriptorDimTy->getName() != "struct.descriptor_dimension")
    return false;

  if (DescriptorDimTy->getNumElements() != 3)
    return false;

  for (auto MemberTy : DescriptorDimTy->elements()) {
    if (MemberTy != IntTy)
      return false;
  }

  return true;
}

Value *ScopBuilder::findFADGlobalNonAlloc(MemAccInst Inst) {
  // match: 4.1 & 4.2 store/load
  if (!isa<LoadInst>(Inst) && !isa<StoreInst>(Inst))
    return nullptr;

  // match: 4
  if (Inst.getAlignment() != 8)
    return nullptr;

  Value *Address = Inst.getPointerOperand();

  const BitCastInst *Bitcast = nullptr;
  // [match: 3]
  if (auto *Slot = dyn_cast<GetElementPtrInst>(Address)) {
    Value *TypedMem = Slot->getPointerOperand();
    // match: 2
    Bitcast = dyn_cast<BitCastInst>(TypedMem);
  } else {
    // match: 2
    Bitcast = dyn_cast<BitCastInst>(Address);
  }

  if (!Bitcast)
    return nullptr;

  auto *MallocMem = Bitcast->getOperand(0);

  // match: 1
  auto *MallocCall = dyn_cast<CallInst>(MallocMem);
  if (!MallocCall)
    return nullptr;

  Function *MallocFn = MallocCall->getCalledFunction();
  if (!(MallocFn && MallocFn->hasName() && MallocFn->getName() == "malloc"))
    return nullptr;

  // Find all uses the malloc'd memory.
  // We are looking for a "store" into a struct with the type being the Fortran
  // descriptor type
  for (auto user : MallocMem->users()) {

    /// match: 5
    auto *MallocStore = dyn_cast<StoreInst>(user);
    if (!MallocStore)
      continue;

    auto *DescriptorGEP =
        dyn_cast<GEPOperator>(MallocStore->getPointerOperand());
    if (!DescriptorGEP)
      continue;

    // match: 5
    auto DescriptorType =
        dyn_cast<StructType>(DescriptorGEP->getSourceElementType());
    if (!(DescriptorType && DescriptorType->hasName()))
      continue;

    Value *Descriptor = dyn_cast<Value>(DescriptorGEP->getPointerOperand());

    if (!Descriptor)
      continue;

    if (!isFortranArrayDescriptor(Descriptor))
      continue;

    return Descriptor;
  }

  return nullptr;
}

Value *ScopBuilder::findFADGlobalAlloc(MemAccInst Inst) {
  // match: 3
  if (!isa<LoadInst>(Inst) && !isa<StoreInst>(Inst))
    return nullptr;

  // match: 3
  if (Inst.getAlignment() != 8)
    return nullptr;

  Value *Slot = Inst.getPointerOperand();

  LoadInst *MemLoad = nullptr;
  // [match: 2]
  if (auto *SlotGEP = dyn_cast<GetElementPtrInst>(Slot)) {
    // match: 1
    MemLoad = dyn_cast<LoadInst>(SlotGEP->getPointerOperand());
  } else {
    // match: 1
    MemLoad = dyn_cast<LoadInst>(Slot);
  }

  if (!MemLoad)
    return nullptr;

  auto *BitcastOperator =
      dyn_cast<BitCastOperator>(MemLoad->getPointerOperand());
  if (!BitcastOperator)
    return nullptr;

  Value *Descriptor = dyn_cast<Value>(BitcastOperator->getOperand(0));
  if (!Descriptor)
    return nullptr;

  if (!isFortranArrayDescriptor(Descriptor))
    return nullptr;

  return Descriptor;
}

Value *ScopBuilder::findFADLocalNonAlloc(MemAccInst Inst) {
  // match: 3
  if (!isa<LoadInst>(Inst) && !isa<StoreInst>(Inst))
    return nullptr;

  // match: 3
  if (Inst.getAlignment() != 8)
    return nullptr;

  Value *Slot = Inst.getPointerOperand();

  BitCastOperator *MemBitcast = nullptr;
  // [match: 2]
  if (auto *SlotGEP = dyn_cast<GetElementPtrInst>(Slot)) {
    // match: 1
    MemBitcast = dyn_cast<BitCastOperator>(SlotGEP->getPointerOperand());
  } else {
    // match: 1
    MemBitcast = dyn_cast<BitCastOperator>(Slot);
  }

  if (!MemBitcast)
    return nullptr;

  Value *Descriptor = dyn_cast<Value>(MemBitcast->getOperand(0));
  if (!Descriptor)
    return nullptr;

  if (!isFortranArrayDescriptor(Descriptor))
    return nullptr;

  return Descriptor;
}

bool ScopBuilder::buildAccessMultiDimFixed(MemAccInst Inst, ScopStmt *Stmt) {
  Value *Val = Inst.getValueOperand();
  Type *ElementType = Val->getType();
  Value *Address = Inst.getPointerOperand();
  const SCEV *AccessFunction =
      SE.getSCEVAtScope(Address, LI.getLoopFor(Inst->getParent()));
  const SCEVUnknown *BasePointer =
      dyn_cast<SCEVUnknown>(SE.getPointerBase(AccessFunction));
  enum MemoryAccess::AccessType AccType =
      isa<LoadInst>(Inst) ? MemoryAccess::READ : MemoryAccess::MUST_WRITE;

  if (auto *BitCast = dyn_cast<BitCastInst>(Address)) {
    auto *Src = BitCast->getOperand(0);
    auto *SrcTy = Src->getType();
    auto *DstTy = BitCast->getType();
    // Do not try to delinearize non-sized (opaque) pointers.
    if ((SrcTy->isPointerTy() && !SrcTy->getPointerElementType()->isSized()) ||
        (DstTy->isPointerTy() && !DstTy->getPointerElementType()->isSized())) {
      return false;
    }
    if (SrcTy->isPointerTy() && DstTy->isPointerTy() &&
        DL.getTypeAllocSize(SrcTy->getPointerElementType()) ==
            DL.getTypeAllocSize(DstTy->getPointerElementType()))
      Address = Src;
  }

  auto *GEP = dyn_cast<GetElementPtrInst>(Address);
  if (!GEP)
    return false;

  std::vector<const SCEV *> Subscripts;
  std::vector<int> Sizes;
  std::tie(Subscripts, Sizes) = getIndexExpressionsFromGEP(GEP, SE);
  auto *BasePtr = GEP->getOperand(0);

  if (auto *BasePtrCast = dyn_cast<BitCastInst>(BasePtr))
    BasePtr = BasePtrCast->getOperand(0);

  // Check for identical base pointers to ensure that we do not miss index
  // offsets that have been added before this GEP is applied.
  if (BasePtr != BasePointer->getValue())
    return false;

  std::vector<const SCEV *> SizesSCEV;

  const InvariantLoadsSetTy &ScopRIL = scop->getRequiredInvariantLoads();

  Loop *SurroundingLoop = Stmt->getSurroundingLoop();
  for (auto *Subscript : Subscripts) {
    InvariantLoadsSetTy AccessILS;
    if (!isAffineExpr(&scop->getRegion(), SurroundingLoop, Subscript, SE,
                      &AccessILS))
      return false;

    for (LoadInst *LInst : AccessILS)
      if (!ScopRIL.count(LInst))
        return false;
  }

  if (Sizes.empty())
    return false;

  SizesSCEV.push_back(nullptr);

  for (auto V : Sizes)
    SizesSCEV.push_back(SE.getSCEV(
        ConstantInt::get(IntegerType::getInt64Ty(BasePtr->getContext()), V)));

  addArrayAccess(Inst, AccType, BasePointer->getValue(), ElementType, true,
                 Subscripts, SizesSCEV, Val);
  return true;
}

bool ScopBuilder::buildAccessMultiDimParam(MemAccInst Inst, ScopStmt *Stmt) {
  if (!PollyDelinearize)
    return false;

  Value *Address = Inst.getPointerOperand();
  Value *Val = Inst.getValueOperand();
  Type *ElementType = Val->getType();
  unsigned ElementSize = DL.getTypeAllocSize(ElementType);
  enum MemoryAccess::AccessType AccType =
      isa<LoadInst>(Inst) ? MemoryAccess::READ : MemoryAccess::MUST_WRITE;

  const SCEV *AccessFunction =
      SE.getSCEVAtScope(Address, LI.getLoopFor(Inst->getParent()));
  const SCEVUnknown *BasePointer =
      dyn_cast<SCEVUnknown>(SE.getPointerBase(AccessFunction));

  assert(BasePointer && "Could not find base pointer");

  auto &InsnToMemAcc = scop->getInsnToMemAccMap();
  auto AccItr = InsnToMemAcc.find(Inst);
  if (AccItr == InsnToMemAcc.end())
    return false;

  std::vector<const SCEV *> Sizes = {nullptr};

  Sizes.insert(Sizes.end(), AccItr->second.Shape->DelinearizedSizes.begin(),
               AccItr->second.Shape->DelinearizedSizes.end());
  // Remove the element size. This information is already provided by the
  // ElementSize parameter. In case the element size of this access and the
  // element size used for delinearization differs the delinearization is
  // incorrect. Hence, we invalidate the scop.
  //
  // TODO: Handle delinearization with differing element sizes.
  auto DelinearizedSize =
      cast<SCEVConstant>(Sizes.back())->getAPInt().getSExtValue();
  Sizes.pop_back();
  if (ElementSize != DelinearizedSize)
    scop->invalidate(DELINEARIZATION, Inst->getDebugLoc());

  addArrayAccess(Inst, AccType, BasePointer->getValue(), ElementType, true,
                 AccItr->second.DelinearizedSubscripts, Sizes, Val);
  return true;
}

bool ScopBuilder::buildAccessMemIntrinsic(MemAccInst Inst, ScopStmt *Stmt) {
  auto *MemIntr = dyn_cast_or_null<MemIntrinsic>(Inst);

  if (MemIntr == nullptr)
    return false;

  auto *L = LI.getLoopFor(Inst->getParent());
  auto *LengthVal = SE.getSCEVAtScope(MemIntr->getLength(), L);
  assert(LengthVal);

  // Check if the length val is actually affine or if we overapproximate it
  InvariantLoadsSetTy AccessILS;
  const InvariantLoadsSetTy &ScopRIL = scop->getRequiredInvariantLoads();

  Loop *SurroundingLoop = Stmt->getSurroundingLoop();
  bool LengthIsAffine = isAffineExpr(&scop->getRegion(), SurroundingLoop,
                                     LengthVal, SE, &AccessILS);
  for (LoadInst *LInst : AccessILS)
    if (!ScopRIL.count(LInst))
      LengthIsAffine = false;
  if (!LengthIsAffine)
    LengthVal = nullptr;

  auto *DestPtrVal = MemIntr->getDest();
  assert(DestPtrVal);

  auto *DestAccFunc = SE.getSCEVAtScope(DestPtrVal, L);
  assert(DestAccFunc);
  // Ignore accesses to "NULL".
  // TODO: We could use this to optimize the region further, e.g., intersect
  //       the context with
  //          isl_set_complement(isl_set_params(getDomain()))
  //       as we know it would be undefined to execute this instruction anyway.
  if (DestAccFunc->isZero())
    return true;

  auto *DestPtrSCEV = dyn_cast<SCEVUnknown>(SE.getPointerBase(DestAccFunc));
  assert(DestPtrSCEV);
  DestAccFunc = SE.getMinusSCEV(DestAccFunc, DestPtrSCEV);
  addArrayAccess(Inst, MemoryAccess::MUST_WRITE, DestPtrSCEV->getValue(),
                 IntegerType::getInt8Ty(DestPtrVal->getContext()),
                 LengthIsAffine, {DestAccFunc, LengthVal}, {nullptr},
                 Inst.getValueOperand());

  auto *MemTrans = dyn_cast<MemTransferInst>(MemIntr);
  if (!MemTrans)
    return true;

  auto *SrcPtrVal = MemTrans->getSource();
  assert(SrcPtrVal);

  auto *SrcAccFunc = SE.getSCEVAtScope(SrcPtrVal, L);
  assert(SrcAccFunc);
  // Ignore accesses to "NULL".
  // TODO: See above TODO
  if (SrcAccFunc->isZero())
    return true;

  auto *SrcPtrSCEV = dyn_cast<SCEVUnknown>(SE.getPointerBase(SrcAccFunc));
  assert(SrcPtrSCEV);
  SrcAccFunc = SE.getMinusSCEV(SrcAccFunc, SrcPtrSCEV);
  addArrayAccess(Inst, MemoryAccess::READ, SrcPtrSCEV->getValue(),
                 IntegerType::getInt8Ty(SrcPtrVal->getContext()),
                 LengthIsAffine, {SrcAccFunc, LengthVal}, {nullptr},
                 Inst.getValueOperand());

  return true;
}

bool ScopBuilder::buildAccessCallInst(MemAccInst Inst, ScopStmt *Stmt) {
  auto *CI = dyn_cast_or_null<CallInst>(Inst);

  if (CI == nullptr)
    return false;

  if (CI->doesNotAccessMemory() || isIgnoredIntrinsic(CI))
    return true;

  bool ReadOnly = false;
  auto *AF = SE.getConstant(IntegerType::getInt64Ty(CI->getContext()), 0);
  auto *CalledFunction = CI->getCalledFunction();
  switch (AA.getModRefBehavior(CalledFunction)) {
  case FMRB_UnknownModRefBehavior:
    llvm_unreachable("Unknown mod ref behaviour cannot be represented.");
  case FMRB_DoesNotAccessMemory:
    return true;
  case FMRB_DoesNotReadMemory:
  case FMRB_OnlyAccessesInaccessibleMem:
  case FMRB_OnlyAccessesInaccessibleOrArgMem:
    return false;
  case FMRB_OnlyReadsMemory:
    GlobalReads.push_back(CI);
    return true;
  case FMRB_OnlyReadsArgumentPointees:
    ReadOnly = true;
  // Fall through
  case FMRB_OnlyAccessesArgumentPointees:
    auto AccType = ReadOnly ? MemoryAccess::READ : MemoryAccess::MAY_WRITE;
    Loop *L = LI.getLoopFor(Inst->getParent());
    for (const auto &Arg : CI->arg_operands()) {
      if (!Arg->getType()->isPointerTy())
        continue;

      auto *ArgSCEV = SE.getSCEVAtScope(Arg, L);
      if (ArgSCEV->isZero())
        continue;

      auto *ArgBasePtr = cast<SCEVUnknown>(SE.getPointerBase(ArgSCEV));
      addArrayAccess(Inst, AccType, ArgBasePtr->getValue(),
                     ArgBasePtr->getType(), false, {AF}, {nullptr}, CI);
    }
    return true;
  }

  return true;
}

void ScopBuilder::buildAccessSingleDim(MemAccInst Inst, ScopStmt *Stmt) {
  Value *Address = Inst.getPointerOperand();
  Value *Val = Inst.getValueOperand();
  Type *ElementType = Val->getType();
  enum MemoryAccess::AccessType AccType =
      isa<LoadInst>(Inst) ? MemoryAccess::READ : MemoryAccess::MUST_WRITE;

  const SCEV *AccessFunction =
      SE.getSCEVAtScope(Address, LI.getLoopFor(Inst->getParent()));
  const SCEVUnknown *BasePointer =
      dyn_cast<SCEVUnknown>(SE.getPointerBase(AccessFunction));

  assert(BasePointer && "Could not find base pointer");
  AccessFunction = SE.getMinusSCEV(AccessFunction, BasePointer);

  // Check if the access depends on a loop contained in a non-affine subregion.
  bool isVariantInNonAffineLoop = false;
  SetVector<const Loop *> Loops;
  findLoops(AccessFunction, Loops);
  for (const Loop *L : Loops)
    if (Stmt->contains(L)) {
      isVariantInNonAffineLoop = true;
      break;
    }

  InvariantLoadsSetTy AccessILS;

  Loop *SurroundingLoop = Stmt->getSurroundingLoop();
  bool IsAffine = !isVariantInNonAffineLoop &&
                  isAffineExpr(&scop->getRegion(), SurroundingLoop,
                               AccessFunction, SE, &AccessILS);

  const InvariantLoadsSetTy &ScopRIL = scop->getRequiredInvariantLoads();
  for (LoadInst *LInst : AccessILS)
    if (!ScopRIL.count(LInst))
      IsAffine = false;

  if (!IsAffine && AccType == MemoryAccess::MUST_WRITE)
    AccType = MemoryAccess::MAY_WRITE;

  addArrayAccess(Inst, AccType, BasePointer->getValue(), ElementType, IsAffine,
                 {AccessFunction}, {nullptr}, Val);
}

void ScopBuilder::buildMemoryAccess(MemAccInst Inst, ScopStmt *Stmt) {

  if (buildAccessMemIntrinsic(Inst, Stmt))
    return;

  if (buildAccessCallInst(Inst, Stmt))
    return;

  if (buildAccessMultiDimFixed(Inst, Stmt))
    return;

  if (buildAccessMultiDimParam(Inst, Stmt))
    return;

  buildAccessSingleDim(Inst, Stmt);
}

void ScopBuilder::buildAccessFunctions(Region &SR) {

  if (scop->isNonAffineSubRegion(&SR)) {
    for (BasicBlock *BB : SR.blocks())
      buildAccessFunctions(*BB, &SR);
    return;
  }

  for (auto I = SR.element_begin(), E = SR.element_end(); I != E; ++I)
    if (I->isSubRegion())
      buildAccessFunctions(*I->getNodeAs<Region>());
    else
      buildAccessFunctions(*I->getNodeAs<BasicBlock>());
}

void ScopBuilder::buildStmts(Region &SR) {

  if (scop->isNonAffineSubRegion(&SR)) {
    Loop *SurroundingLoop = LI.getLoopFor(SR.getEntry());
    auto &BoxedLoops = scop->getBoxedLoops();
    while (BoxedLoops.count(SurroundingLoop))
      SurroundingLoop = SurroundingLoop->getParentLoop();
    scop->addScopStmt(&SR, SurroundingLoop);
    return;
  }

  for (auto I = SR.element_begin(), E = SR.element_end(); I != E; ++I)
    if (I->isSubRegion())
      buildStmts(*I->getNodeAs<Region>());
    else {
      Loop *SurroundingLoop = LI.getLoopFor(I->getNodeAs<BasicBlock>());
      scop->addScopStmt(I->getNodeAs<BasicBlock>(), SurroundingLoop);
    }
}

void ScopBuilder::buildAccessFunctions(BasicBlock &BB,
                                       Region *NonAffineSubRegion,
                                       bool IsExitBlock) {
  // We do not build access functions for error blocks, as they may contain
  // instructions we can not model.
  if (isErrorBlock(BB, scop->getRegion(), LI, DT) && !IsExitBlock)
    return;

  ScopStmt *Stmt = scop->getStmtFor(&BB);

  for (Instruction &Inst : BB) {
    PHINode *PHI = dyn_cast<PHINode>(&Inst);
    if (PHI)
      buildPHIAccesses(PHI, NonAffineSubRegion, IsExitBlock);

    // For the exit block we stop modeling after the last PHI node.
    if (!PHI && IsExitBlock)
      break;

    if (auto MemInst = MemAccInst::dyn_cast(Inst)) {
      assert(Stmt && "Cannot build access function in non-existing statement");
      buildMemoryAccess(MemInst, Stmt);
    }

    if (isIgnoredIntrinsic(&Inst))
      continue;

    // PHI nodes have already been modeled above and TerminatorInsts that are
    // not part of a non-affine subregion are fully modeled and regenerated
    // from the polyhedral domains. Hence, they do not need to be modeled as
    // explicit data dependences.
    if (!PHI && (!isa<TerminatorInst>(&Inst) || NonAffineSubRegion))
      buildScalarDependences(&Inst);

    if (!IsExitBlock)
      buildEscapingDependences(&Inst);
  }
}

MemoryAccess *ScopBuilder::addMemoryAccess(
    BasicBlock *BB, Instruction *Inst, MemoryAccess::AccessType AccType,
    Value *BaseAddress, Type *ElementType, bool Affine, Value *AccessValue,
    ArrayRef<const SCEV *> Subscripts, ArrayRef<const SCEV *> Sizes,
    MemoryKind Kind) {
  ScopStmt *Stmt = scop->getStmtFor(BB);

  // Do not create a memory access for anything not in the SCoP. It would be
  // ignored anyway.
  if (!Stmt)
    return nullptr;

  bool isKnownMustAccess = false;

  // Accesses in single-basic block statements are always excuted.
  if (Stmt->isBlockStmt())
    isKnownMustAccess = true;

  if (Stmt->isRegionStmt()) {
    // Accesses that dominate the exit block of a non-affine region are always
    // executed. In non-affine regions there may exist MemoryKind::Values that
    // do not dominate the exit. MemoryKind::Values will always dominate the
    // exit and MemoryKind::PHIs only if there is at most one PHI_WRITE in the
    // non-affine region.
    if (DT.dominates(BB, Stmt->getRegion()->getExit()))
      isKnownMustAccess = true;
  }

  // Non-affine PHI writes do not "happen" at a particular instruction, but
  // after exiting the statement. Therefore they are guaranteed to execute and
  // overwrite the old value.
  if (Kind == MemoryKind::PHI || Kind == MemoryKind::ExitPHI)
    isKnownMustAccess = true;

  if (!isKnownMustAccess && AccType == MemoryAccess::MUST_WRITE)
    AccType = MemoryAccess::MAY_WRITE;

  auto *Access = new MemoryAccess(Stmt, Inst, AccType, BaseAddress, ElementType,
                                  Affine, Subscripts, Sizes, AccessValue, Kind);

  scop->addAccessFunction(Access);
  Stmt->addAccess(Access);
  return Access;
}

void ScopBuilder::addArrayAccess(
    MemAccInst MemAccInst, MemoryAccess::AccessType AccType, Value *BaseAddress,
    Type *ElementType, bool IsAffine, ArrayRef<const SCEV *> Subscripts,
    ArrayRef<const SCEV *> Sizes, Value *AccessValue) {
  ArrayBasePointers.insert(BaseAddress);
  auto *MemAccess = addMemoryAccess(
      MemAccInst->getParent(), MemAccInst, AccType, BaseAddress, ElementType,
      IsAffine, AccessValue, Subscripts, Sizes, MemoryKind::Array);

  if (!DetectFortranArrays)
    return;

  if (Value *FAD = findFADGlobalNonAlloc(MemAccInst))
    MemAccess->setFortranArrayDescriptor(FAD);
  else if (Value *FAD = findFADGlobalAlloc(MemAccInst))
    MemAccess->setFortranArrayDescriptor(FAD);
  else if (Value *FAD = findFADLocalNonAlloc(MemAccInst))
    MemAccess->setFortranArrayDescriptor(FAD);
}

void ScopBuilder::ensureValueWrite(Instruction *Inst) {
  ScopStmt *Stmt = scop->getStmtFor(Inst);

  // Inst not defined within this SCoP.
  if (!Stmt)
    return;

  // Do not process further if the instruction is already written.
  if (Stmt->lookupValueWriteOf(Inst))
    return;

  addMemoryAccess(Inst->getParent(), Inst, MemoryAccess::MUST_WRITE, Inst,
                  Inst->getType(), true, Inst, ArrayRef<const SCEV *>(),
                  ArrayRef<const SCEV *>(), MemoryKind::Value);
}

void ScopBuilder::ensureValueRead(Value *V, BasicBlock *UserBB) {
  ScopStmt *UserStmt = scop->getStmtFor(UserBB);
  auto *Scope = LI.getLoopFor(UserBB);
  auto VUse = VirtualUse::create(scop.get(), UserStmt, Scope, V, false);
  switch (VUse.getKind()) {
  case VirtualUse::Constant:
  case VirtualUse::Block:
  case VirtualUse::Synthesizable:
  case VirtualUse::Hoisted:
  case VirtualUse::Intra:
    // Uses of these kinds do not need a MemoryAccess.
    break;

  case VirtualUse::ReadOnly:
    // Add MemoryAccess for invariant values only if requested.
    if (!ModelReadOnlyScalars)
      break;

    LLVM_FALLTHROUGH;
  case VirtualUse::Inter:

    // Do not create another MemoryAccess for reloading the value if one already
    // exists.
    if (UserStmt->lookupValueReadOf(V))
      break;

    addMemoryAccess(UserBB, nullptr, MemoryAccess::READ, V, V->getType(), true,
                    V, ArrayRef<const SCEV *>(), ArrayRef<const SCEV *>(),
                    MemoryKind::Value);

    // Inter-statement uses need to write the value in their defining statement.
    if (VUse.isInter())
      ensureValueWrite(cast<Instruction>(V));
    break;
  }
}

void ScopBuilder::ensurePHIWrite(PHINode *PHI, BasicBlock *IncomingBlock,
                                 Value *IncomingValue, bool IsExitBlock) {
  // As the incoming block might turn out to be an error statement ensure we
  // will create an exit PHI SAI object. It is needed during code generation
  // and would be created later anyway.
  if (IsExitBlock)
    scop->getOrCreateScopArrayInfo(PHI, PHI->getType(), {},
                                   MemoryKind::ExitPHI);

  ScopStmt *IncomingStmt = scop->getStmtFor(IncomingBlock);
  if (!IncomingStmt)
    return;

  // Take care for the incoming value being available in the incoming block.
  // This must be done before the check for multiple PHI writes because multiple
  // exiting edges from subregion each can be the effective written value of the
  // subregion. As such, all of them must be made available in the subregion
  // statement.
  ensureValueRead(IncomingValue, IncomingBlock);

  // Do not add more than one MemoryAccess per PHINode and ScopStmt.
  if (MemoryAccess *Acc = IncomingStmt->lookupPHIWriteOf(PHI)) {
    assert(Acc->getAccessInstruction() == PHI);
    Acc->addIncoming(IncomingBlock, IncomingValue);
    return;
  }

  MemoryAccess *Acc =
      addMemoryAccess(IncomingStmt->getEntryBlock(), PHI,
                      MemoryAccess::MUST_WRITE, PHI, PHI->getType(), true, PHI,
                      ArrayRef<const SCEV *>(), ArrayRef<const SCEV *>(),
                      IsExitBlock ? MemoryKind::ExitPHI : MemoryKind::PHI);
  assert(Acc);
  Acc->addIncoming(IncomingBlock, IncomingValue);
}

void ScopBuilder::addPHIReadAccess(PHINode *PHI) {
  addMemoryAccess(PHI->getParent(), PHI, MemoryAccess::READ, PHI,
                  PHI->getType(), true, PHI, ArrayRef<const SCEV *>(),
                  ArrayRef<const SCEV *>(), MemoryKind::PHI);
}

#ifndef NDEBUG
static void verifyUse(Scop *S, Use &Op, LoopInfo &LI) {
  auto PhysUse = VirtualUse::create(S, Op, &LI, false);
  auto VirtUse = VirtualUse::create(S, Op, &LI, true);
  assert(PhysUse.getKind() == VirtUse.getKind());
}

/// Check the consistency of every statement's MemoryAccesses.
///
/// The check is carried out by expecting the "physical" kind of use (derived
/// from the BasicBlocks instructions resides in) to be same as the "virtual"
/// kind of use (derived from a statement's MemoryAccess).
///
/// The "physical" uses are taken by ensureValueRead to determine whether to
/// create MemoryAccesses. When done, the kind of scalar access should be the
/// same no matter which way it was derived.
///
/// The MemoryAccesses might be changed by later SCoP-modifying passes and hence
/// can intentionally influence on the kind of uses (not corresponding to the
/// "physical" anymore, hence called "virtual"). The CodeGenerator therefore has
/// to pick up the virtual uses. But here in the code generator, this has not
/// happened yet, such that virtual and physical uses are equivalent.
static void verifyUses(Scop *S, LoopInfo &LI, DominatorTree &DT) {
  for (auto *BB : S->getRegion().blocks()) {
    auto *Stmt = S->getStmtFor(BB);
    if (!Stmt)
      continue;

    for (auto &Inst : *BB) {
      if (isIgnoredIntrinsic(&Inst))
        continue;

      // Branch conditions are encoded in the statement domains.
      if (isa<TerminatorInst>(&Inst) && Stmt->isBlockStmt())
        continue;

      // Verify all uses.
      for (auto &Op : Inst.operands())
        verifyUse(S, Op, LI);

      // Stores do not produce values used by other statements.
      if (isa<StoreInst>(Inst))
        continue;

      // For every value defined in the block, also check that a use of that
      // value in the same statement would not be an inter-statement use. It can
      // still be synthesizable or load-hoisted, but these kind of instructions
      // are not directly copied in code-generation.
      auto VirtDef =
          VirtualUse::create(S, Stmt, Stmt->getSurroundingLoop(), &Inst, true);
      assert(VirtDef.getKind() == VirtualUse::Synthesizable ||
             VirtDef.getKind() == VirtualUse::Intra ||
             VirtDef.getKind() == VirtualUse::Hoisted);
    }
  }

  if (S->hasSingleExitEdge())
    return;

  // PHINodes in the SCoP region's exit block are also uses to be checked.
  for (auto &Inst : *S->getRegion().getExit()) {
    if (!isa<PHINode>(Inst))
      break;

    for (auto &Op : Inst.operands())
      verifyUse(S, Op, LI);
  }
}
#endif

void ScopBuilder::buildScop(Region &R, AssumptionCache &AC) {
  scop.reset(new Scop(R, SE, LI, *SD.getDetectionContext(&R)));

  buildStmts(R);
  buildAccessFunctions(R);

  // In case the region does not have an exiting block we will later (during
  // code generation) split the exit block. This will move potential PHI nodes
  // from the current exit block into the new region exiting block. Hence, PHI
  // nodes that are at this point not part of the region will be.
  // To handle these PHI nodes later we will now model their operands as scalar
  // accesses. Note that we do not model anything in the exit block if we have
  // an exiting block in the region, as there will not be any splitting later.
  if (!scop->hasSingleExitEdge())
    buildAccessFunctions(*R.getExit(), nullptr,
                         /* IsExitBlock */ true);

  // Create memory accesses for global reads since all arrays are now known.
  auto *AF = SE.getConstant(IntegerType::getInt64Ty(SE.getContext()), 0);
  for (auto *GlobalRead : GlobalReads)
    for (auto *BP : ArrayBasePointers)
      addArrayAccess(MemAccInst(GlobalRead), MemoryAccess::READ, BP,
                     BP->getType(), false, {AF}, {nullptr}, GlobalRead);

  scop->buildInvariantEquivalenceClasses();

  if (!scop->buildDomains(&R, DT, LI))
    return;

  scop->addUserAssumptions(AC, DT, LI);

  // Remove empty statements.
  // Exit early in case there are no executable statements left in this scop.
  scop->simplifySCoP(false);
  if (scop->isEmpty())
    return;

  // The ScopStmts now have enough information to initialize themselves.
  for (ScopStmt &Stmt : *scop)
    Stmt.init(LI);

  // Check early for a feasible runtime context.
  if (!scop->hasFeasibleRuntimeContext())
    return;

  // Check early for profitability. Afterwards it cannot change anymore,
  // only the runtime context could become infeasible.
  if (!scop->isProfitable(UnprofitableScalarAccs)) {
    scop->invalidate(PROFITABLE, DebugLoc());
    return;
  }

  scop->buildSchedule(LI);

  scop->finalizeAccesses();

  scop->realignParams();
  scop->addUserContext();

  // After the context was fully constructed, thus all our knowledge about
  // the parameters is in there, we add all recorded assumptions to the
  // assumed/invalid context.
  scop->addRecordedAssumptions();

  scop->simplifyContexts();
  if (!scop->buildAliasChecks(AA))
    return;

  scop->hoistInvariantLoads();
  scop->canonicalizeDynamicBasePtrs();
  scop->verifyInvariantLoads();
  scop->simplifySCoP(true);

  // Check late for a feasible runtime context because profitability did not
  // change.
  if (!scop->hasFeasibleRuntimeContext())
    return;

#ifndef NDEBUG
  verifyUses(scop.get(), LI, DT);
#endif
}

ScopBuilder::ScopBuilder(Region *R, AssumptionCache &AC, AliasAnalysis &AA,
                         const DataLayout &DL, DominatorTree &DT, LoopInfo &LI,
                         ScopDetection &SD, ScalarEvolution &SE)
    : AA(AA), DL(DL), DT(DT), LI(LI), SD(SD), SE(SE) {

  Function *F = R->getEntry()->getParent();

  DebugLoc Beg, End;
  getDebugLocations(getBBPairForRegion(R), Beg, End);
  std::string Msg = "SCoP begins here.";
  emitOptimizationRemarkAnalysis(F->getContext(), DEBUG_TYPE, *F, Beg, Msg);

  buildScop(*R, AC);

  DEBUG(scop->print(dbgs()));

  if (!scop->hasFeasibleRuntimeContext()) {
    InfeasibleScops++;
    Msg = "SCoP ends here but was dismissed.";
    scop.reset();
  } else {
    Msg = "SCoP ends here.";
    ++ScopFound;
    if (scop->getMaxLoopDepth() > 0)
      ++RichScopFound;
  }

  emitOptimizationRemarkAnalysis(F->getContext(), DEBUG_TYPE, *F, End, Msg);
}

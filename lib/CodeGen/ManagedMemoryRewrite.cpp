//===---- ManagedMemoryRewrite.cpp - Rewrite global & malloc'd memory -----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Take a module and rewrite:
// 1. `malloc` -> `polly_mallocManaged`
// 2. `free` -> `polly_freeManaged`
// 3. global arrays with initializers -> global arrays that are initialized
//                                       with a constructor call to
//                                       `polly_mallocManaged`.
//
//===----------------------------------------------------------------------===//

#include "polly/CodeGen/CodeGeneration.h"
#include "polly/CodeGen/IslAst.h"
#include "polly/CodeGen/IslNodeBuilder.h"
#include "polly/CodeGen/PPCGCodeGeneration.h"
#include "polly/CodeGen/Utils.h"
#include "polly/DependenceInfo.h"
#include "polly/LinkAllPasses.h"
#include "polly/Options.h"
#include "polly/ScopDetection.h"
#include "polly/ScopInfo.h"
#include "polly/Support/SCEVValidator.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/CaptureTracking.h"
#include "llvm/Analysis/GlobalsModRef.h"
#include "llvm/Analysis/ScalarEvolutionAliasAnalysis.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

static cl::opt<bool> RewriteAllocas(
    "polly-acc-rewrite-allocas",
    cl::desc(
        "Ask the managed memory rewriter to also rewrite alloca instructions"),
    cl::Hidden, cl::init(false), cl::ZeroOrMore, cl::cat(PollyCategory));

#define DEBUG_TYPE "polly-acc-rewrite-managed-memory"
namespace {

static llvm::Function *getOrCreatePollyMallocManaged(Module &M) {
  const char *Name = "polly_mallocManaged";
  Function *F = M.getFunction(Name);

  // If F is not available, declare it.
  if (!F) {
    GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
    PollyIRBuilder Builder(M.getContext());
    // TODO: How do I get `size_t`? I assume from DataLayout?
    FunctionType *Ty = FunctionType::get(Builder.getInt8PtrTy(),
                                         {Builder.getInt64Ty()}, false);
    F = Function::Create(Ty, Linkage, Name, &M);
  }

  return F;
}

static llvm::Function *getOrCreatePollyFreeManaged(Module &M) {
  const char *Name = "polly_freeManaged";
  Function *F = M.getFunction(Name);

  // If F is not available, declare it.
  if (!F) {
    GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
    PollyIRBuilder Builder(M.getContext());
    // TODO: How do I get `size_t`? I assume from DataLayout?
    FunctionType *Ty =
        FunctionType::get(Builder.getVoidTy(), {Builder.getInt8PtrTy()}, false);
    F = Function::Create(Ty, Linkage, Name, &M);
  }

  return F;
}

// Expand a constant expression `Cur`, which is used at instruction `Parent`
// at index `index`.
// Since a constant expression can expand to multiple instructions, store all
// the expands into a set called `Expands`.
// Note that this goes inorder on the constant expression tree.
// A * ((B * D) + C)
// will be processed with first A, then B * D, then B, then D, and then C.
// Though ConstantExprs are not treated as "trees" but as DAGs, since you can
// have something like this:
//    *
//   /  \
//   \  /
//    (D)
//
// For the purposes of this expansion, we expand the two occurences of D
// separately. Therefore, we expand the DAG into the tree:
//  *
// / \
// D  D
// TODO: We don't _have_to do this, but this is the simplest solution.
// We can write a solution that keeps track of which constants have been
// already expanded.
static void expandConstantExpr(ConstantExpr *Cur, PollyIRBuilder &Builder,
                               Instruction *Parent, int index,
                               SmallPtrSet<Instruction *, 4> &Expands) {
  assert(Cur && "invalid constant expression passed");

  Instruction *I = Cur->getAsInstruction();
  Expands.insert(I);
  Parent->setOperand(index, I);

  assert(I && "unable to convert ConstantExpr to Instruction");
  // The things that `Parent` uses (its operands) should be created
  // before `Parent`.
  Builder.SetInsertPoint(Parent);
  Builder.Insert(I);

  DEBUG(dbgs() << "Expanded: " << *I << "\n";);
  for (unsigned i = 0; i < Cur->getNumOperands(); i++) {
    Value *Op = Cur->getOperand(i);
    assert(isa<Constant>(Op) && "constant must have a constant operand");

    if (ConstantExpr *CExprOp = dyn_cast<ConstantExpr>(Op))
      expandConstantExpr(CExprOp, Builder, I, i, Expands);
  }
}

// Edit all uses of `OldVal` to NewVal` in `Inst`. This will rewrite
// `ConstantExpr`s that are used in the `Inst`.
static void rewriteArrToPtr(Instruction *Inst, Value *OldVal, Value *NewVal,
                            PollyIRBuilder &Builder) {

  // We use a worklist based algorithm that keeps a frontier of
  // `User`s we need to rewrite in `Next`, and the current iterations
  // in `Current`.
  SmallPtrSet<Instruction *, 4> Next;
  SmallPtrSet<Instruction *, 4> Current = {Inst};

  while (!Current.empty()) {

    for (Instruction *CurInst : Current) {

      Builder.SetInsertPoint(CurInst);
      for (unsigned i = 0; i < CurInst->getNumOperands(); i++) {
        User *OperandAsUser = dyn_cast<User>(CurInst->getOperand(i));
        assert(OperandAsUser && "operandAsUser obtained was not a User.");

        if (isa<BlockAddress>(OperandAsUser) ||
            isa<ConstantAggregate>(OperandAsUser) ||
            isa<ConstantData>(OperandAsUser))
          continue;

        if (isa<Instruction>(OperandAsUser) ||
            isa<GlobalValue>(OperandAsUser)) {
          if (OperandAsUser == OldVal)
            CurInst->setOperand(i, NewVal);
        } else {
          assert(isa<Constant>(OperandAsUser));
          assert(!isa<GlobalValue>(OperandAsUser));
          // Only things that can contain a reference is a ConstantExpr
          ConstantExpr *ValueConstExpr = dyn_cast<ConstantExpr>(OperandAsUser);
          assert(ValueConstExpr && "this must be a ValueConstExpr");

          expandConstantExpr(ValueConstExpr, Builder, CurInst, i, Next);

        } // end else
      }   // end operands for
    }     // end for current

    Current.clear();
    Current = Next;

    Next.clear();
  } // end worklist
}

// Given a value `Current`, return all Instructions that may contain `Current`
// in an expression.
// We need this auxiliary function, because if we have a
// `Constant` that is a user of `V`, we need to recurse into the
// `Constant`s uses to gather the root instruciton.
static void getInstructionUsersOfValue(Value *V,
                                       SmallVector<Instruction *, 4> &Owners) {
  if (auto *I = dyn_cast<Instruction>(V)) {
    Owners.push_back(I);
  } else {
    // Anything that is a `User` must be a constant or an instruction.
    auto *C = cast<Constant>(V);
    for (Use &CUse : C->uses())
      getInstructionUsersOfValue(CUse.getUser(), Owners);
  }
}

static void
replaceGlobalArray(Module &M, const DataLayout &DL, GlobalVariable &Array,
                   SmallPtrSet<GlobalVariable *, 4> &ReplacedGlobals) {
  static const unsigned AddrSpace = 0;
  // We only want arrays.
  ArrayType *ArrayTy = dyn_cast<ArrayType>(Array.getType()->getElementType());
  if (!ArrayTy)
    return;
  Type *ElemTy = ArrayTy->getElementType();
  PointerType *ElemPtrTy = ElemTy->getPointerTo(AddrSpace);

  // We only wish to replace stuff with internal linkage. Otherwise,
  // our type edit from [T] to T* would be illegal across modules.
  // It is interesting that most arrays don't seem to be tagged with internal
  // linkage?
  if (GlobalValue::isWeakForLinker(Array.getLinkage()) && false) {
    return;
  }

  if (!Array.hasInitializer() ||
      !isa<ConstantAggregateZero>(Array.getInitializer()))
    return;

  // At this point, we have committed to replacing this array.
  ReplacedGlobals.insert(&Array);

  std::string NewName = (Array.getName() + Twine(".toptr")).str();
  GlobalVariable *ReplacementToArr =
      cast<GlobalVariable>(M.getOrInsertGlobal(NewName, ElemPtrTy));
  ReplacementToArr->setInitializer(ConstantPointerNull::get(ElemPtrTy));

  Function *PollyMallocManaged = getOrCreatePollyMallocManaged(M);
  Twine FnName = Array.getName() + ".constructor";
  PollyIRBuilder Builder(M.getContext());
  FunctionType *Ty = FunctionType::get(Builder.getVoidTy(), false);
  const GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
  Function *F = Function::Create(Ty, Linkage, FnName, &M);
  BasicBlock *Start = BasicBlock::Create(M.getContext(), "entry", F);
  Builder.SetInsertPoint(Start);

  int ArraySizeInt = DL.getTypeAllocSizeInBits(ArrayTy) * 8;
  Value *ArraySize = Builder.getInt64(ArraySizeInt);
  ArraySize->setName("array.size");

  Value *AllocatedMemRaw =
      Builder.CreateCall(PollyMallocManaged, {ArraySize}, "mem.raw");
  Value *AllocatedMemTyped =
      Builder.CreatePointerCast(AllocatedMemRaw, ElemPtrTy, "mem.typed");
  Builder.CreateStore(AllocatedMemTyped, ReplacementToArr);
  Builder.CreateRetVoid();

  const int Priority = 0;
  appendToGlobalCtors(M, F, Priority, ReplacementToArr);

  SmallVector<Instruction *, 4> ArrayUserInstructions;
  // Get all instructions that use array. We need to do this weird thing
  // because `Constant`s that contain this array neeed to be expanded into
  // instructions so that we can replace their parameters. `Constant`s cannot
  // be edited easily, so we choose to convert all `Constant`s to
  // `Instruction`s and handle all of the uses of `Array` uniformly.
  for (Use &ArrayUse : Array.uses())
    getInstructionUsersOfValue(ArrayUse.getUser(), ArrayUserInstructions);

  for (Instruction *UserOfArrayInst : ArrayUserInstructions) {

    Builder.SetInsertPoint(UserOfArrayInst);
    // <ty>** -> <ty>*
    Value *ArrPtrLoaded = Builder.CreateLoad(ReplacementToArr, "arrptr.load");
    // <ty>* -> [ty]*
    Value *ArrPtrLoadedBitcasted = Builder.CreateBitCast(
        ArrPtrLoaded, PointerType::get(ArrayTy, AddrSpace), "arrptr.bitcast");
    rewriteArrToPtr(UserOfArrayInst, &Array, ArrPtrLoadedBitcasted, Builder);
  }
}

// We return all `allocas` that may need to be converted to a call to
// cudaMallocManaged.
static void getAllocasToBeManaged(Function &F,
                                  SmallSet<AllocaInst *, 4> &Allocas) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *Alloca = dyn_cast<AllocaInst>(&I);
      if (!Alloca)
        continue;
      dbgs() << "Checking if " << *Alloca << "may be captured: ";

      if (PointerMayBeCaptured(Alloca, /* ReturnCaptures */ false,
                               /* StoreCaptures */ true)) {
        Allocas.insert(Alloca);
        DEBUG(dbgs() << "YES (captured)\n");
      } else {
        DEBUG(dbgs() << "NO (not captured)\n");
      }
    }
  }
}

static void rewriteAllocaAsManagedMemory(AllocaInst *Alloca,
                                         const DataLayout &DL) {
  DEBUG(dbgs() << "rewriting: " << *Alloca << " to managed mem.\n");
  Module *M = Alloca->getModule();
  assert(M && "Alloca does not have a module");

  PollyIRBuilder Builder(M->getContext());
  Builder.SetInsertPoint(Alloca);

  Value *MallocManagedFn = getOrCreatePollyMallocManaged(*Alloca->getModule());
  const int Size = DL.getTypeAllocSize(Alloca->getType()->getElementType());
  Value *SizeVal = Builder.getInt64(Size);
  Value *RawManagedMem = Builder.CreateCall(MallocManagedFn, {SizeVal});
  Value *Bitcasted = Builder.CreateBitCast(RawManagedMem, Alloca->getType());

  Bitcasted->takeName(Alloca);
  Alloca->replaceAllUsesWith(Bitcasted);
  Alloca->eraseFromParent();

  Function *F = Alloca->getFunction();
  assert(F && "Alloca has invalid function");

  for (BasicBlock &BB : *F) {
    ReturnInst *Return = dyn_cast<ReturnInst>(BB.getTerminator());
    if (!Return)
      continue;
    Builder.SetInsertPoint(Return);

    Value *FreeManagedFn = getOrCreatePollyFreeManaged(*M);
    Builder.CreateCall(FreeManagedFn, {RawManagedMem});
  }
}

class ManagedMemoryRewritePass : public ModulePass {
public:
  static char ID;
  GPUArch Architecture;
  GPURuntime Runtime;

  ManagedMemoryRewritePass() : ModulePass(ID) {}
  virtual bool runOnModule(Module &M) {
    const DataLayout &DL = M.getDataLayout();

    Function *Malloc = M.getFunction("malloc");

    if (Malloc) {
      Function *PollyMallocManaged = getOrCreatePollyMallocManaged(M);
      assert(PollyMallocManaged && "unable to create polly_mallocManaged");
      Malloc->replaceAllUsesWith(PollyMallocManaged);
      Malloc->eraseFromParent();
    }

    Function *Free = M.getFunction("free");

    if (Free) {
      Function *PollyFreeManaged = getOrCreatePollyFreeManaged(M);
      assert(PollyFreeManaged && "unable to create polly_freeManaged");
      Free->replaceAllUsesWith(PollyFreeManaged);
      Free->eraseFromParent();
    }

    SmallPtrSet<GlobalVariable *, 4> GlobalsToErase;
    for (GlobalVariable &Global : M.globals())
      replaceGlobalArray(M, DL, Global, GlobalsToErase);
    for (GlobalVariable *G : GlobalsToErase)
      G->eraseFromParent();

    // Rewrite allocas to cudaMallocs if we are asked to do so.
    if (RewriteAllocas) {
      SmallSet<AllocaInst *, 4> AllocasToBeManaged;
      for (Function &F : M.functions())
        getAllocasToBeManaged(F, AllocasToBeManaged);

      for (AllocaInst *Alloca : AllocasToBeManaged)
        rewriteAllocaAsManagedMemory(Alloca, DL);
    }

    return true;
  }
};

} // namespace
char ManagedMemoryRewritePass::ID = 42;

Pass *polly::createManagedMemoryRewritePassPass(GPUArch Arch,
                                                GPURuntime Runtime) {
  ManagedMemoryRewritePass *pass = new ManagedMemoryRewritePass();
  pass->Runtime = Runtime;
  pass->Architecture = Arch;
  return pass;
}

INITIALIZE_PASS_BEGIN(
    ManagedMemoryRewritePass, "polly-acc-rewrite-managed-memory",
    "Polly - Rewrite all allocations in heap & data section to managed memory",
    false, false)
INITIALIZE_PASS_DEPENDENCY(PPCGCodeGeneration);
INITIALIZE_PASS_DEPENDENCY(DependenceInfo);
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_DEPENDENCY(RegionInfoPass);
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass);
INITIALIZE_PASS_DEPENDENCY(ScopDetectionWrapperPass);
INITIALIZE_PASS_END(
    ManagedMemoryRewritePass, "polly-acc-rewrite-managed-memory",
    "Polly - Rewrite all allocations in heap & data section to managed memory",
    false, false)

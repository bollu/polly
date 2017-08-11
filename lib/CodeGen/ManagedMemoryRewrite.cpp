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
#include "llvm/Analysis/GlobalsModRef.h"
#include "llvm/Analysis/ScalarEvolutionAliasAnalysis.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/DerivedUser.h"
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


#define DEBUG_TYPE "polly-acc-rewrite-managed-memory"
namespace {

static llvm::Function *GetOrCreatePollyMallocManaged(Module &M) {
  // TODO: should I allow this pass to be a standalone pass that
  // doesn't care if PollyManagedMemory is enabled or not?
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

static llvm::Function *GetOrCreatePollyFreeManaged(Module &M) {
  // TODO: should I allow this pass to be a standalone pass that
  // doesn't care if PollyManagedMemory is enabled or not?
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

// Expand the constant expression Cur using Builder. This will recursively
// expand `Cur` to arrive at a set of instructions.
// `Expands` is populated all the expanded instructions.
// NOTE: this simply `insert`s into Expands.
static void expandConstantExpr(ConstantExpr *Cur,
                                       PollyIRBuilder &Builder,
                                       Instruction *Parent,
                                       int index,
                                       std::set<std::pair<Instruction *, Instruction *>> &Expands) {
  DEBUG(dbgs() << "\n\n\nExpanding: " << *Cur << "\n";
        dbgs() << "Parent: " << *Parent << "\n";);
  assert(Cur && "invalid constant expression passed");
  std::vector<std::pair<int, Instruction *>> Replacements;

  Instruction *I = Cur->getAsInstruction();
  Expands.insert({Parent, I});
  Parent->setOperand(index, I);

  assert(I && "unable to convert ConstantExpr to Instruction");
  // I need instructions to be created before this.
  Builder.SetInsertPoint(Parent);
  Builder.Insert(I);

  errs() << "Expanded: " << *I << "\n";
  for (unsigned i = 0; i < Cur->getNumOperands(); i++) {
    Constant *COp = dyn_cast<Constant>(Cur->getOperand(i));
    assert(COp && "constant must have a constant operand");
    if (isa<ConstantExpr>(COp)) {
          expandConstantExpr(dyn_cast<ConstantExpr>(COp), Builder, I, i, Expands);
    };
  }
}

// rewrite a GEP to strip of the first index
// We need to do this because earlier it used to be @[i32 x <size>]
// It is now i32*. We don't need an extra "@" dereference.
// Parameters:
// MaybeGEP: A `User` that might be a GEP
// ArrToRewrite: Global array we wish to rewrite to a pointer (@A)
// NewLoadedPtr: New pointer value to rewrite the global array with (A.toptr that has been loaded)
// IRBuilder: IRBuilder instance
static bool rewriteGEP(Instruction *MaybeGEP, Instruction *Parent, Value *ArrToRewrite, Value *NewLoadedPtr,
                       PollyIRBuilder &IRBuilder,
                       std::set<Instruction *> &InstsToBeDeleted ) {
    DEBUG(dbgs() << "\n\n\n";
    dbgs() << "CurInst: " << *MaybeGEP << "\n");
    if (Parent)
        dbgs() << "Owning Inst: " << *Parent << "\n";
    else
        dbgs() << "Owning Inst: " << "NONE" << "\n";

    dbgs() << "TargerArr: " << *ArrToRewrite << "\n";
  GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(MaybeGEP);

  if (!GEP)
    return false;
  if (!(GEP->getPointerOperand() == ArrToRewrite))
    return false;

  DEBUG(dbgs() << " Is GEP\n";);

  auto Indices = GEP->indices();
  std::vector<Value *> NewIndices(Indices.begin() + 1, Indices.end());

  Value *NewGEP = IRBuilder.CreateGEP(NewLoadedPtr, NewIndices, "newgep");

  // Either the owning instruction is a GEP, or is an instruction that
  // contains a GEP.
  if (Parent == nullptr) {
      DEBUG(dbgs() << "Replacing Parent(" << *Parent << ")\n\twith NewGEP(" << *NewGEP << ")...\n");
      Parent->replaceAllUsesWith(NewGEP);
      InstsToBeDeleted.insert(Parent);
  }
  else {

      if (GEP->getNumUses() == 1) {
          DEBUG(dbgs() << "\n\n\n@@@ GEP dropping to 0" << *GEP << "\n");
      };
      DEBUG(dbgs() << "Replacing GEP(" << *GEP << ")\n\twith NewGEP(" << *NewGEP << ")\n\tin Parent(" << *Parent << ")...\n");
      Parent->replaceUsesOfWith(GEP, NewGEP);
      DEBUG(dbgs() << "Parent after replacement: " << *Parent << "\n";);
      DEBUG(dbgs() << "GEP->numUses() " << GEP->getNumUses() << "\n";);

      // GEP can be used by other people, so we can't remove it.
      if (GEP->getNumUses() == 0) {
          InstsToBeDeleted.insert(GEP);
          DEBUG(dbgs() << "@@@ GEP AT 0: " << *GEP << "\n";);
      }
  }
  return true;
}

// Edit all uses of `ArrPtrToRewrite` to `NewLoadedPtr` in `Inst`.
// This will change all `GEP`s into `ArrPtrToRewrite` to `NewLoadedPtr`, re-indexing
// the GEPs correctly as well.
// It will change all raw uses of `ArrPtrToRewrite` to `NewBitcastedPtr`.
static void rewriteArrToPtr(Instruction *Inst, Value *ArrPtrToRewrite, Value *NewLoadedPtr,
                            Value *NewBitcastedPtr, PollyIRBuilder &Builder,
                            std::set<Instruction *>&InstsToBeDeleted) {

  // We use a worklist based algorithm that keep the frontier of
  // `User`s we need to rewrite in `Next`, and the current iterations
  // in `Current`.
  std::set<std::pair<Instruction *, Instruction*>> Next;
  std::set<std::pair<Instruction *, Instruction *>> Current = {std::make_pair(nullptr, Inst)};

  while (!Current.empty()) {

    for (const std::pair<Instruction *, Instruction *> &ParentInstPair : Current) {
        Instruction *CurInst = ParentInstPair.second;
        Instruction *Parent = ParentInstPair.first;

        Builder.SetInsertPoint(CurInst);
      // Try to rewrite the current as a GEP.
      // If we can generate a GEP from the instruction, then we are done,
      // because we have replaced the old array with the new pointer.
      if (rewriteGEP(CurInst, Parent, ArrPtrToRewrite, NewLoadedPtr, Builder, InstsToBeDeleted))
        continue;

      for (unsigned i = 0; i < CurInst->getNumOperands(); i++) {
        User *OperandAsUser = dyn_cast<User>(CurInst->getOperand(i));

        if (!OperandAsUser) {
          errs() << "\t\t" << *OperandAsUser << " obtained from: " << *CurInst
                 << "is not a user!. Trying to replace: "
                 << *ArrPtrToRewrite << " with: " << *NewBitcastedPtr << "failed.\n";
          report_fatal_error("rewriteArrToPtr failed with value that was not user");
        }
        assert(OperandAsUser && "operandAsUser uninitialized");

        if (isa<Instruction>(OperandAsUser)) {
          if (OperandAsUser == ArrPtrToRewrite) {
            CurInst->setOperand(i, NewBitcastedPtr);
          }
        } else {
          assert(isa<Constant>(OperandAsUser));

          if (isa<BlockAddress>(OperandAsUser) ||
              isa<ConstantAggregate>(OperandAsUser) ||
              isa<ConstantData>(OperandAsUser))
            continue;

          if (isa<GlobalValue>(OperandAsUser)) {
            if (OperandAsUser == ArrPtrToRewrite) {
              CurInst->setOperand(i, NewBitcastedPtr);
            }
            continue;
          }

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
static void getContainingInstructions(Value *Current,
                                      std::vector<Instruction *> &Owners) {
  Instruction *I;
  Constant *C;
  if ((I = dyn_cast<Instruction>(Current))) {
    Owners.push_back(I);
  } else if ((C = dyn_cast<Constant>(Current))) {
    for (Use &CUse : C->uses()) {
      getContainingInstructions(CUse.getUser(), Owners);
    }
  } else {
    errs() << "(" << *Current
           << ") is neither an instruction nor a constant!.\n"
              "The process of finding the owning instruction reached a node "
              "with unknown replacement strategy";
    report_fatal_error("unable to find owning instruction");
    llvm_unreachable("should never reach here from getContainingInstruction");
  }
}

static void RewriteGlobalArray(Module &M, const DataLayout &DL,
                               GlobalVariable &Array,
                               std::set<GlobalVariable *> &ReplacedGlobals,
                               std::set<Instruction *> &InstsToBeDeleted) {
  static const unsigned AddrSpace = 0;
  // We only want arrays.
  ArrayType *ArrayTy = dyn_cast<ArrayType>(Array.getType()->getElementType());
  if (!ArrayTy)
    return;
  Type *ElemTy = ArrayTy->getElementType();
  PointerType *ElemPtrTy = PointerType::get(ElemTy, AddrSpace);

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
      dyn_cast<GlobalVariable>(M.getOrInsertGlobal(NewName, ElemPtrTy));
  ReplacementToArr->setInitializer(ConstantPointerNull::get(ElemPtrTy));

  Function *PollyMallocManaged = GetOrCreatePollyMallocManaged(M);
  Twine FnName = Array.getName() + ".constructor";
  PollyIRBuilder Builder(M.getContext());
  FunctionType *Ty = FunctionType::get(Builder.getVoidTy(), {}, false);
  const GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
  Function *F = Function::Create(Ty, Linkage, FnName, &M);
  BasicBlock *Start = BasicBlock::Create(M.getContext(), "entry", F);
  Builder.SetInsertPoint(Start);

  int ArraySizeInt = DL.getTypeAllocSizeInBits(ArrayTy) * 100;
  Value *ArraySize = ConstantInt::get(Builder.getInt64Ty(), ArraySizeInt);
  ArraySize->setName("array.size");

  Value *AllocatedMemRaw =
      Builder.CreateCall(PollyMallocManaged, {ArraySize}, "mem.raw");
  Value *AllocatedMemTyped =
      Builder.CreatePointerCast(AllocatedMemRaw, ElemPtrTy, "mem.typed");
  Builder.CreateStore(AllocatedMemTyped, ReplacementToArr);
  Builder.CreateRetVoid();

  // HACK: refactor the priority stuff.
  static int priority = 0;
  appendToGlobalCtors(M, F, priority++, ReplacementToArr);

  std::vector<Instruction *> ArrayUserInstructions;
  // Get all instructions that use array. We need to do this weird thing
  // because `Constant`s that contain
  for (Use &ArrayUse : Array.uses()) {
    getContainingInstructions(ArrayUse.getUser(), ArrayUserInstructions);
  }

  for (Instruction *UserOfArrayInst : ArrayUserInstructions) {
      if (InstsToBeDeleted.count(UserOfArrayInst)) continue;

    Builder.SetInsertPoint(UserOfArrayInst);
    Value *ArrPtrLoaded = Builder.CreateLoad(ReplacementToArr, "arrptr.load");
    Value *ArrPtrBitcasted = Builder.CreateBitCast(ReplacementToArr, PointerType::get(ArrayTy, AddrSpace), "arrptr.bitcast");
    rewriteArrToPtr(UserOfArrayInst, &Array, ArrPtrLoaded, ArrPtrBitcasted,
        Builder, InstsToBeDeleted);
  }

}

class ManagedMemoryRewritePass : public ModulePass {
public:
  static char ID;
  GPUArch Architecture;
  GPURuntime Runtime;
  const DataLayout *DL;

  ManagedMemoryRewritePass() : ModulePass(ID) {}

  virtual bool runOnModule(Module &M) {
    DL = &M.getDataLayout();

    Function *Malloc = M.getFunction("malloc");

    if (Malloc) {
      Function *PollyMallocManaged = GetOrCreatePollyMallocManaged(M);
      assert(PollyMallocManaged && "unable to create polly_mallocManaged");
      Malloc->replaceAllUsesWith(PollyMallocManaged);
      Malloc->eraseFromParent();
    }

    Function *Free = M.getFunction("free");

    if (Free) {
      Function *PollyFreeManaged = GetOrCreatePollyFreeManaged(M);
      assert(PollyFreeManaged && "unable to create polly_freeManaged");
      Free->replaceAllUsesWith(PollyFreeManaged);
      Free->eraseFromParent();
    }

    std::set<Instruction *>InstsToBeDeleted;
    std::set<GlobalVariable *> GlobalsToErase;

    for (GlobalVariable &Global : M.globals()) {
      RewriteGlobalArray(M, *DL, Global, GlobalsToErase, InstsToBeDeleted);
    }

    DEBUG(dbgs() << "\n\n\n=====Module=====\n";
    M.dump();
    dbgs() << "=====\n";);

    for(Instruction *Inst : InstsToBeDeleted) {
        errs() << "\n\nRemoving: " << *Inst << "...\n";
        Inst->eraseFromParent();
        errs() << "Successful\n";
    }
    // Erase all globals from the parent
    for(GlobalVariable *G : GlobalsToErase) {
        G->eraseFromParent();
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

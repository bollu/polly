//===------ ManagedMemoryRewrite.cpp - Rewrite global & malloc'd memory.
//---===//
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
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/DerivedUser.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
namespace {

static llvm::Function *GetOrCreatePollyMallocManaged(Module &M) {
  // TODO: should I allow this pass to be a standalone pass that
  // doesn't care if PollyManagedMemory is enabled or not?
  assert(PollyManagedMemory &&
         "One should only rewrite malloc & free to"
         "polly_{malloc,free}Managed with managed memory enabled.");
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
  assert(PollyManagedMemory &&
         "One should only rewrite malloc & free to"
         "polly_{malloc,free}Managed with managed memory enabled.");
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
// expand Instruction. `Expands` contains all the expanded instructions.
static Instruction* ExpandConstantExpr(ConstantExpr *Cur,
        PollyIRBuilder &Builder, std::vector<Instruction *> &Expands)  {
    errs() << "ExpandConstantExpr: " << *Cur << "\n\n";
    std::vector<std::pair<int, Instruction*> > Replacements;
    for(unsigned i = 0; i < Cur->getNumOperands(); i++) {
        Constant *C = dyn_cast<Constant >(C->getOperand(i));
        assert (C && "constant must have a constant operand");
        if (isa<ConstantExpr>(Cur)) {
            Instruction *Replacement = ExpandConstantExpr(Cur, Builder, Expands);
            Replacements.push_back(std::make_pair(i, Replacement));
        };
    }

    Instruction *I = Cur->getAsInstruction();
    for(std::pair<int, Instruction *> &Replacement : Replacements) {
        I->setOperand(Replacement.first, Replacement.second);
    }
    Expands.push_back(I);
    Builder.Insert(I);
    return I;
}

static void editAllUses(Instruction *Inst, Value *Old, Value *New,
        PollyIRBuilder &Builder) {

    std::vector<Instruction *>Next;
    std::vector<Instruction *>Current = {Inst};

    for(Instruction *CurInst : Current) {

        errs() << "\n\n*** " << *CurInst  << " | NumOperand: " << CurInst->getNumOperands() << "\n";
        for(unsigned i = 0; i < CurInst->getNumOperands(); i++) {
            User *ValueUser = dyn_cast<User>(CurInst->getOperand(i));

            if (!ValueUser) {
                errs() << "\t\t" << *ValueUser << " obtained from: " << *CurInst << "is not a user!."
                    " Trying to replace: " << *Old << " with: " << *New << "failed.\n";
                report_fatal_error("editAllUses failed with value that was not user");
            }

            errs() << " -" << *ValueUser << "\n";
            // if (isa<DerivedUser>) continue;
            // assert (!isa<DerivedUser>(ValueUser) && "Value should not be a DerivedUser");

            // Only choice in User Instruction,DerivedUser,  Constant
            // NOTE: does this even make sense?
            if ((isa<Instruction>(ValueUser) || isa<DerivedUser>(ValueUser))) {
                if (ValueUser == Old) CurInst->setOperand(i, New);
            }
            else {
                assert(isa<Constant>(ValueUser));

                if (isa<BlockAddress>(ValueUser) ||
                        isa<ConstantAggregate>(ValueUser) ||
                        isa<ConstantData>(ValueUser) || isa<GlobalValue>(ValueUser))  continue;

                if (isa<GlobalValue>(ValueUser) && ValueUser == Old) {
                    CurInst->setOperand(i, New);
                    continue;
                }

                // Only things that can contain a reference is a ConstantExpr
                ConstantExpr *ValueConstExpr = dyn_cast<ConstantExpr>(ValueUser);
                assert (ValueConstExpr && "this must be a ValueConstExpr");

                ExpandConstantExpr(ValueConstExpr, Builder, Next);

            }// end else
        }// end operands for
 
        // TODO: move.
        Current = Next;
        Next.clear();
    }// end worklist
}

// Given a value `Current`, return all Instructions that may contain `Current`
// in an expression.
static void getContainingInstructions(Value *Current, std::vector<Instruction*> &Owners) {
  Instruction *I;
  Constant *C;
  if ((I = dyn_cast<Instruction>(Current))) {
      errs() << "#Found owner for: " << *Current << "\n\t- " << *I << "\n\n";
      Owners.push_back(I);
  } else if ((C = dyn_cast<Constant>(Current))) {
      for(Use &CUse : C->uses()) {
          // if (CUse == C) continue;
          getContainingInstructions(CUse.getUser(), Owners);
      }
  } else {
    errs() << "(" << *Current
           << ") is neither an instruction nor a constant!.\n"
        "The process of finding the owning instruction reached a node with unknown replacement strategy";
    report_fatal_error("unable to find owning instruction");
    llvm_unreachable("should never reach here from getContainingInstruction");
  }

}

static void RewriteGlobalArray(Module &M, const DataLayout &DL,
                               GlobalVariable &Array, std::vector<GlobalVariable*> &ReplacedGlobals) {
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
  ReplacedGlobals.push_back(&Array);

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


  errs() << "Done appending to global ctors\n";
  std::vector<Instruction *> ArrayUserInstructions;
  // Get all instructions that use array. We need to do this weird thing
  // because `Constant`s that contain
  for(Use &ArrayUse : Array.uses()) {
      getContainingInstructions(ArrayUse.getUser(), ArrayUserInstructions);
  }

  for(Instruction *UserOfArrayInst : ArrayUserInstructions) {
      Builder.SetInsertPoint(UserOfArrayInst);
      Value *ArrPtrBitcast =  Builder.CreateBitCast(ReplacementToArr,
              PointerType::get(ArrayTy, AddrSpace), "arrptr.bitcast");
      Value *ArrPtrLoaded =  Builder.CreateLoad(ArrPtrBitcast, "arrptr.bitcast.load");

     std::set<Value *> SeenSet; 
     editAllUses(UserOfArrayInst, &Array, ArrPtrBitcast, Builder);
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

    std::vector<GlobalVariable*> GlobalsToErase;
    for (GlobalVariable &Global : M.globals()) {
      RewriteGlobalArray(M, *DL,Global, GlobalsToErase);
    }

    // Erase all globals from the parent
    for(GlobalVariable *GV : GlobalsToErase) {};
        //GV->eraseFromParent();

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

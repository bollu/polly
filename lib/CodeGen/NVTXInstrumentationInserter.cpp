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


#define DEBUG_TYPE "polly-acc-rewrite-managed-memory"
namespace {
    //nvtxRangePushA(const char *)
    //nvtxRangePop();

static llvm::Function *getOrCreateNVTXRangePush(Module &M) {
  const char *Name = "nvtxRangePushA"; // A for ASCII
  Function *F = M.getFunction(Name);

  // If F is not available, declare it.
  if (!F) {
    GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
    PollyIRBuilder Builder(M.getContext());
    // TODO: How do I get `size_t`? I assume from DataLayout?
    FunctionType *Ty = FunctionType::get(Builder.getVoidTy(),
                                         {Builder.getInt8PtrTy()}, false);
    F = Function::Create(Ty, Linkage, Name, &M);
  }

  return F;
}

static llvm::Function *getOrCreateNVTXRangePop(Module &M) {
  const char *Name = "nvtxRangePop";
  Function *F = M.getFunction(Name);

  // If F is not available, declare it.
  if (!F) {
    GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
    PollyIRBuilder Builder(M.getContext());
    // TODO: How do I get `size_t`? I assume from DataLayout?
    FunctionType *Ty =
        FunctionType::get(Builder.getVoidTy(), {}, false);
    F = Function::Create(Ty, Linkage, Name, &M);
  }

  return F;
}


class NVTXInstrumentationInserterPass : public ModulePass {
public:
  static char ID;
  NVTXInstrumentationInserterPass() : ModulePass(ID) {}
  virtual bool runOnModule(Module &M) {
      for(Function &F: M) {
          if (F.isDeclaration()) continue;
          const std::string Name = F.getName();
          BasicBlock *Entry = &F.getEntryBlock();
          PollyIRBuilder Builder(Entry);
          Builder.SetInsertPoint(Entry->getFirstNonPHIOrDbgOrLifetime());
          Value *FnName = Builder.CreateGlobalStringPtr(Name);
          Builder.CreateCall(getOrCreateNVTXRangePush(M), {FnName});

          for(BasicBlock &BB : F) {
              // BB exits.
              if (isa<ReturnInst>(BB.getTerminator())) {
                  Builder.SetInsertPoint(BB.getTerminator());
                  Builder.CreateCall(getOrCreateNVTXRangePop(M),{});
              }
          }

          errs() << "###############\n";
          errs() << "F:\n";
          errs() << F << "\n";
          errs() << "###############\n";
          
      }
    return true;
  }
};

} // namespace
char NVTXInstrumentationInserterPass::ID = 42;

Pass *polly::createNVTXInstrumentationInserterPass() {
    return new NVTXInstrumentationInserterPass();
}

INITIALIZE_PASS_BEGIN(
    NVTXInstrumentationInserterPass, "nvtx-instrumentation",
    "Instrument all functions with NVTX calls to show up in nvvp",
    false, false)
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_DEPENDENCY(RegionInfoPass);
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass);
INITIALIZE_PASS_END(
    NVTXInstrumentationInserterPass, "nvtx-instrumentation",
    "Instrument all functions with NVTX calls to show up in nvvp",
    false, false)

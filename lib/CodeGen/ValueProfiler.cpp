//===---- ValueProfiling.cpp - Infrastructure for Value Profiling ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Insert the initialization and teardown for the experiemental value
// profiling infrastructure in Polly. depends on:
// https://github.com/bollu/polly-valueprofiler
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

static cl::opt<std::string> InputFilepath(
    "polly-value-profiler-input-filepath",
    cl::desc("file path of the JSON output from the value profiler"),
    cl::Hidden, cl::init(""), cl::ZeroOrMore, cl::cat(PollyCategory));


static cl::opt<std::string> OutputFilepath(
    "polly-value-profiler-output-filepath",
    cl::desc("file path of the JSON output from the value profiler"),
    cl::Hidden, cl::init(""), cl::ZeroOrMore, cl::cat(PollyCategory));

#define DEBUG_TYPE "polly-value-profiler"
namespace {

static llvm::Function *getOrCreateFunction(Module &M, const char *Name, llvm::FunctionType *Ty) {
  Function *F = M.getFunction(Name);

  // If F is not available, declare it.
  if (!F) {
    GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
    F = Function::Create(Ty, Linkage, Name, &M);
  }

  return F;
}


static llvm::Function *getOrCreateVpDumpValuesProto(Module &M)  {
    PollyIRBuilder Builder(M.getContext());
    return getOrCreateFunction(M, "vp_dump_values", FunctionType::get(Builder.getVoidTy(), 
                Builder.getInt8Ty()->getPointerTo(), /*isVarArg=*/false));
}

void createDestructor(Module &M) {
    PollyIRBuilder Builder(M.getContext());

    Function *Dump = getOrCreateVpDumpValuesProto(M);

    FunctionType *FTy = FunctionType::get(Builder.getVoidTy(), {},  /*isVarArg=*/false);
    Function *Destructor = Function::Create(FTy, Function::ExternalLinkage, "dtor_vp_dump_values", &M);
    BasicBlock *Entry = BasicBlock::Create(M.getContext(), "entry", Destructor);
    Builder.SetInsertPoint(Entry);

    Value *FilenameStr = Builder.CreateGlobalStringPtr(OutputFilepath);
    
    Builder.CreateCall(Dump, FilenameStr);
    Builder.CreateRetVoid();
    appendToGlobalDtors(M, Destructor, /*Priority=*/0);

}

void readInput() {
}

class ValueProfiler : public ModulePass {
public:
  static char ID;

  ValueProfiler() : ModulePass(ID) {}
  virtual bool runOnModule(Module &M) {
    // assert(OutputFilepath != "" &&
    //        "value profiler pass scheduled without setting output file path");
      if (InputFilepath != "")
          readInput();

      if (OutputFilepath != "")
          createDestructor(M);

      assert((OutputFilepath != "" || InputFilepath != "") && "value profiler run with neither input nor output pass scheduled");
    return true;
  }
};

} // namespace
char ValueProfiler::ID = 42;

Pass *polly::createValueProfilerPass() {
  ValueProfiler *pass = new ValueProfiler();
  return pass;
}

INITIALIZE_PASS_BEGIN(
    ValueProfiler, "polly-value-profiler",
    "Setup and teardown of exprimental value profiler in Polly", false, false)
INITIALIZE_PASS_END(
    ValueProfiler, "polly-value-profiler",
    "Setup and teardown of experimental value profiler in polly", false, false)

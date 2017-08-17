//===---- ScopInliner.cpp - Polyhedral based inliner ----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
/// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Take a SCC and:
// 1. If it has more than one component, bail out (contains cycles)
// 2. If it has just one component, and if the function is entirely a scop,
//    inline it.
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
#include "llvm/Analysis/CallGraphSCCPass.h"
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
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/IPO/AlwaysInliner.h"

#define DEBUG_TYPE "polly-scop-inliner"
namespace {
class ScopInliner : public CallGraphSCCPass {
public:
  static char ID;


  ScopInliner() : CallGraphSCCPass(ID) {
  }
  /// runOnSCC - This method should be implemented by the subclass to perform
  /// whatever action is necessary for the specified SCC.  Note that
  /// non-recursive (or only self-recursive) functions will have an SCC size of
  /// 1, where recursive portions of the call graph will have SCC size > 1.
  ///
  /// SCC passes that add or delete functions to the SCC are required to update
  /// the SCC list, otherwise stale pointers may be dereferenced.
  ///
   bool runOnSCC(CallGraphSCC &SCC) override {
       PassBuilder PB;
       FunctionAnalysisManager FAM;
       FAM.registerPass([] { return ScopAnalysis(); });
       PB.registerFunctionAnalyses(FAM);

      // We do not try to inline non-trivial SCCs because this would lead to
      // "infinite" inlining if we are not careful.
      if (SCC.size() > 1) return false;
      assert(SCC.size() == 1 && "found empty SCC");
      Function *F = (*SCC.begin())->getFunction();

      if (!F || F->isDeclaration()) return false;
      RegionInfo &RI = FAM.getResult<RegionInfoAnalysis>(*F);
      ScopDetection &SD = FAM.getResult<ScopAnalysis>(*F);

      const bool HasScopAsTopLevelRegion = SD.ValidRegions.count(RI.getTopLevelRegion()) > 0;

      if (HasScopAsTopLevelRegion) {
          F->addFnAttr(llvm::Attribute::AlwaysInline);

          ModuleAnalysisManager MAM;
          PB.registerModuleAnalyses(MAM);
          ModulePassManager MPM;
          MPM.addPass(AlwaysInlinerPass());
          Module *M = F->getParent();
          assert(M && "Function has illegal module");
          MPM.run(*M, MAM);
      }



      errs() << "-" << F->getName() << " | " << HasScopAsTopLevelRegion << "\n";
      return false;

  };

  void getAnalysisUsage(AnalysisUsage &AU) const override {
      CallGraphSCCPass::getAnalysisUsage(AU);

  }

};

} // namespace
char ScopInliner::ID;

Pass *polly::createScopInlinerPass() {
  ScopInliner *pass = new ScopInliner();
  return pass;
}

INITIALIZE_PASS_BEGIN(
    ScopInliner, "polly-scop-inliner",
    "inline functions based on how much of the function is a scop.",
    false, false)
INITIALIZE_PASS_END(
    ScopInliner, "polly-scop-inliner",
    "inline functions based on how much of the function is a scop.",
    false, false)


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

#include "polly/LinkAllPasses.h"
#include "polly/RegisterPasses.h"
#include "polly/ScopDetection.h"
#include "llvm/Analysis/CallGraphSCCPass.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/IPO/AlwaysInliner.h"
#include "llvm/Transforms/IPO/Inliner.h"

#define DEBUG_TYPE "polly-scop-inliner"

using namespace polly;
extern bool polly::PollyAllowFullFunction;

namespace {
class ScopInliner : public LegacyInlinerBase {
private:
        std::map<Function *, InlineCost> InlineCostCache;
public:
  static char ID;

  ScopInliner() : LegacyInlinerBase(ID, /*InsertLifetime*/ true) {
    // initializeAlwaysInlinerLegacyPassPass(*PassRegistry::getPassRegistry());
  }

  bool doInitialization(CallGraph &CG) override {
    if (!polly::PollyAllowFullFunction) {
      report_fatal_error(
          "Aborting from ScopInliner because it only makes sense to run with "
          "-polly-allow-full-function. "
          "The heurtistic for ScopInliner checks that the full function is a "
          "Scop, which happens if and only if polly-allow-full-function is "
          " enabled. "
          " If not, the entry block is not included in the Scop");
    }
    return LegacyInlinerBase::doInitialization(CG);
  }

  bool doFinalization(CallGraph &CG) override {
      InlineCostCache.clear();
      return LegacyInlinerBase::doFinalization(CG);
  }

  InlineCost getInlineCost(CallSite CS) override {
    Function *F = CS.getCalledFunction();

    if (!F || F->isDeclaration())
      return InlineCost::getNever();

    DEBUG(dbgs() << "Scop inliner running on: " << F->getName() << " | ");

    std::map<Function *, InlineCost>::iterator It;
    if ((It = InlineCostCache.find(F)) != InlineCostCache.end()) {
        DEBUG(dbgs() << "(cached) will inline? " << (bool)It->second << ".\n");
        return It->second;
    }

    PassBuilder PB;
    FunctionAnalysisManager FAM;
    FAM.registerPass([] { return ScopAnalysis(); });
    PB.registerFunctionAnalyses(FAM);

    RegionInfo &RI = FAM.getResult<RegionInfoAnalysis>(*F);
    ScopDetection &SD = FAM.getResult<ScopAnalysis>(*F);

    const auto TopLevelRegion = RI.getTopLevelRegion();

    // Whether the entire function can be modeled as a Scop.
    const bool IsFullyModeledAsScop =
        SD.ValidRegions.count(TopLevelRegion) > 0;

    // Whether the scop contains all the children of the top-level region.
    const bool IsModeledByTopLevelChildren = [&] {
        for (auto ScopRegion : SD.ValidRegions)
            if (ScopRegion->getParent() == TopLevelRegion)
                return true;
        return false;
    }();

    const InlineCost AnalyzedInlineCost = [&] {
        if (IsFullyModeledAsScop || IsModeledByTopLevelChildren)
            return InlineCost::getAlways();
        return InlineCost::getNever();
    }();

    assert(InlineCostCache.find(F) == InlineCostCache.end() &&
            "Cached inlining analysis was not used.");
    // Can't use InlineCostCache[F] = AnalyzedInlineCost because
    // copy-ctor of InlineCost has been deleted. Joy.
    InlineCostCache.insert(std::make_pair(F, AnalyzedInlineCost));
    DEBUG(dbgs() << "will inline? " << (bool)(AnalyzedInlineCost) << ".\n");

    // If we decided to inline, then invalidate call site.
    if (AnalyzedInlineCost) {
        Function *Caller = CS.getCaller();
        assert(Caller && "Callsite has invalid caller");

        InlineCostCache.erase(Caller);
    }

    return AnalyzedInlineCost;
  }

  // Do whatever alwaysinliner does.
  bool runOnSCC(CallGraphSCC &SCC) override { return inlineCalls(SCC); }

};

} // namespace
char ScopInliner::ID;

Pass *polly::createScopInlinerPass() {
  ScopInliner *pass = new ScopInliner();
  return pass;
}

INITIALIZE_PASS_BEGIN(
    ScopInliner, "polly-scop-inliner",
    "inline functions based on how much of the function is a scop.", false,
    false)
INITIALIZE_PASS_END(
    ScopInliner, "polly-scop-inliner",
    "inline functions based on how much of the function is a scop.", false,
    false)

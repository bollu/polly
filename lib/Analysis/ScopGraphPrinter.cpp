//===- GraphPrinter.cpp - Create a DOT output describing the Scop. --------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Create a DOT output describing the Scop.
//
// For each function a dot file is created that shows the control flow graph of
// the function and highlights the detected Scops.
//
//===----------------------------------------------------------------------===//

#include "polly/LinkAllPasses.h"
#include "polly/ScopDetection.h"
#include "polly/Support/ScopLocation.h"
#include "llvm/Analysis/DOTGraphTraitsPass.h"
#include "llvm/Analysis/RegionInfo.h"
#include "llvm/Analysis/RegionIterator.h"
#include "llvm/Support/CommandLine.h"

static const unsigned PAIRED12_GREEN_INDEX = 1;
using namespace polly;
using namespace llvm;
static cl::opt<std::string>
    ViewFilter("polly-view-only",
               cl::desc("Only view functions that match this pattern"),
               cl::Hidden, cl::init(""), cl::ZeroOrMore);

static cl::opt<bool> ViewAll("polly-view-all",
                             cl::desc("Also show functions without any scops"),
                             cl::Hidden, cl::init(false), cl::ZeroOrMore);

namespace llvm {
template <>
struct GraphTraits<ScopDetection *> : public GraphTraits<RegionInfo *> {
  static NodeRef getEntryNode(ScopDetection *SD) {
    return GraphTraits<RegionInfo *>::getEntryNode(SD->getRI());
  }
  static nodes_iterator nodes_begin(ScopDetection *SD) {
    return nodes_iterator::begin(getEntryNode(SD));
  }
  static nodes_iterator nodes_end(ScopDetection *SD) {
    return nodes_iterator::end(getEntryNode(SD));
  }
};

template <>
struct GraphTraits<ScopDetectionWrapperPass *>
    : public GraphTraits<ScopDetection *> {
  static NodeRef getEntryNode(ScopDetectionWrapperPass *P) {
    return GraphTraits<ScopDetection *>::getEntryNode(&P->getSD());
  }
  static nodes_iterator nodes_begin(ScopDetectionWrapperPass *P) {
    return nodes_iterator::begin(getEntryNode(P));
  }
  static nodes_iterator nodes_end(ScopDetectionWrapperPass *P) {
    return nodes_iterator::end(getEntryNode(P));
  }
};

template <> struct DOTGraphTraits<RegionNode *> : public DefaultDOTGraphTraits {
  DOTGraphTraits(bool isSimple = false) : DefaultDOTGraphTraits(isSimple) {}

  std::string getNodeLabel(RegionNode *Node, RegionNode *Graph) {
    if (!Node->isSubRegion()) {
      BasicBlock *BB = Node->getNodeAs<BasicBlock>();

      if (isSimple())
        return DOTGraphTraits<const Function *>::getSimpleNodeLabel(
            BB, BB->getParent());
      else
        return DOTGraphTraits<const Function *>::getCompleteNodeLabel(
            BB, BB->getParent());
    }

    return "Not implemented";
  }
};

template <>
struct DOTGraphTraits<ScopDetectionWrapperPass *>
    : public DOTGraphTraits<RegionNode *> {
  DOTGraphTraits(bool isSimple = false)
      : DOTGraphTraits<RegionNode *>(isSimple) {}
  static std::string getGraphName(ScopDetectionWrapperPass *SD) {
    return "Scop Graph";
  }

  std::string getEdgeAttributes(RegionNode *srcNode,
                                GraphTraits<RegionInfo *>::ChildIteratorType CI,
                                ScopDetectionWrapperPass *P) {
    RegionNode *destNode = *CI;
    auto *SD = &P->getSD();

    if (srcNode->isSubRegion() || destNode->isSubRegion())
      return "";

    // In case of a backedge, do not use it to define the layout of the nodes.
    BasicBlock *srcBB = srcNode->getNodeAs<BasicBlock>();
    BasicBlock *destBB = destNode->getNodeAs<BasicBlock>();

    RegionInfo *RI = SD->getRI();
    Region *R = RI->getRegionFor(destBB);

    while (R && R->getParent())
      if (R->getParent()->getEntry() == destBB)
        R = R->getParent();
      else
        break;

    if (R && R->getEntry() == destBB && R->contains(srcBB))
      return "constraint=false";

    return "";
  }

  std::string getNodeLabel(RegionNode *Node, ScopDetectionWrapperPass *P) {
    return DOTGraphTraits<RegionNode *>::getNodeLabel(
        Node, reinterpret_cast<RegionNode *>(
                  P->getSD().getRI()->getTopLevelRegion()));
  }

  static std::string escapeString(std::string String) {
    std::string Escaped;

    for (const auto &C : String) {
      if (C == '"')
        Escaped += '\\';

      Escaped += C;
    }
    return Escaped;
  }

  static unsigned getNextColor(unsigned c) {
      unsigned cnext = (c + 1) % 12 + 1;
      // We do not want green again.
      if (cnext == PAIRED12_GREEN_INDEX) cnext = PAIRED12_GREEN_INDEX + 1;
      return cnext;
  }

  // Print the cluster of the subregions. This groups the single basic blocks
  // and adds a different background color for each group.
  static void printRegionCluster(const ScopDetection *SD, const Region *R,
                                 raw_ostream &O, unsigned depth = 0, unsigned colorPrev=1) {
    O.indent(2 * depth) << "subgraph cluster_" << static_cast<const void *>(R)
                        << " {\n";
    unsigned LineBegin, LineEnd;
    std::string FileName;

    getDebugLocation(R, LineBegin, LineEnd, FileName);

    std::string Location;
    if (LineBegin != (unsigned)-1) {
      Location = escapeString(FileName + ":" + std::to_string(LineBegin) + "-" +
                              std::to_string(LineEnd) + "\n");
    }

    std::string ErrorMessage = SD->regionIsInvalidBecause(R);
    ErrorMessage = escapeString(ErrorMessage);
    O.indent(2 * (depth + 1))
        << "label = \"" << Location << ErrorMessage << "\";\n";
    
    const std::string colorString = [&] () -> std::string {
        // maximal region scops are green, others are general colored, regions
        // that do not belong to scop have no color.
        if  (SD->regionIsInvalidBecause(R) == "") {
            unsigned colorIndex;
            if (SD->isMaxRegionInScop(*R))
                colorIndex = PAIRED12_GREEN_INDEX;
            else
                colorIndex = getNextColor(colorPrev);

            return std::string("[fillcolor=") + std::to_string(colorIndex) + std::string(", style=filled, colorscheme=paired12]");
        }
        else
            return "";
    } ();
    

    for (const auto &SubRegion : *R)
      printRegionCluster(SD, SubRegion.get(), O, depth + 1, getNextColor(colorPrev));

    RegionInfo *RI = R->getRegionInfo();

    for (const auto &BB : R->blocks())
      if (RI->getRegionFor(BB) == R)
        O.indent(2 * (depth + 1))
            << "Node"
            << static_cast<void *>(RI->getTopLevelRegion()->getBBNode(BB))
            <<  colorString           << ";\n";

    O.indent(2 * depth) << "}\n";
  }
  static void
  addCustomGraphFeatures(const ScopDetectionWrapperPass *SD,
                         GraphWriter<ScopDetectionWrapperPass *> &GW) {
    raw_ostream &O = GW.getOStream();
    O << "\tcolorscheme = \"paired12\"\n";
    printRegionCluster(&SD->getSD(), SD->getSD().getRI()->getTopLevelRegion(),
                       O, 4);
  }
};

} // end namespace llvm

struct ScopViewer
    : public DOTGraphTraitsViewer<ScopDetectionWrapperPass, false> {
  static char ID;
  ScopViewer()
      : DOTGraphTraitsViewer<ScopDetectionWrapperPass, false>("scops", ID) {}
  bool processFunction(Function &F, ScopDetectionWrapperPass &SD) override {
    if (ViewFilter != "" && !F.getName().count(ViewFilter))
      return false;

    if (ViewAll)
      return true;

    // Check that at least one scop was detected.
    return std::distance(SD.getSD().begin(), SD.getSD().end()) > 0;
  }
};
char ScopViewer::ID = 0;

struct ScopOnlyViewer
    : public DOTGraphTraitsViewer<ScopDetectionWrapperPass, true> {
  static char ID;
  ScopOnlyViewer()
      : DOTGraphTraitsViewer<ScopDetectionWrapperPass, true>("scopsonly", ID) {}
};
char ScopOnlyViewer::ID = 0;

struct ScopPrinter
    : public DOTGraphTraitsPrinter<ScopDetectionWrapperPass, false> {
  static char ID;
  ScopPrinter()
      : DOTGraphTraitsPrinter<ScopDetectionWrapperPass, false>("scops", ID) {}
};
char ScopPrinter::ID = 0;

struct ScopOnlyPrinter
    : public DOTGraphTraitsPrinter<ScopDetectionWrapperPass, true> {
  static char ID;
  ScopOnlyPrinter()
      : DOTGraphTraitsPrinter<ScopDetectionWrapperPass, true>("scopsonly", ID) {
  }
};
char ScopOnlyPrinter::ID = 0;

static RegisterPass<ScopViewer> X("view-scops",
                                  "Polly - View Scops of function");

static RegisterPass<ScopOnlyViewer>
    Y("view-scops-only",
      "Polly - View Scops of function (with no function bodies)");

static RegisterPass<ScopPrinter> M("dot-scops",
                                   "Polly - Print Scops of function");

static RegisterPass<ScopOnlyPrinter>
    N("dot-scops-only",
      "Polly - Print Scops of function (with no function bodies)");

Pass *polly::createDOTViewerPass() { return new ScopViewer(); }

Pass *polly::createDOTOnlyViewerPass() { return new ScopOnlyViewer(); }

Pass *polly::createDOTPrinterPass() { return new ScopPrinter(); }

Pass *polly::createDOTOnlyPrinterPass() { return new ScopOnlyPrinter(); }

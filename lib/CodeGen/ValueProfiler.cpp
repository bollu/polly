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
#include "json/reader.h"
#include "json/writer.h"
#include <fstream>

std::string polly::PollyValueProfilerInputFilepath;
static cl::opt<std::string, true> XInputFilepath(
    "polly-value-profiler-input-filepath",
    cl::desc("file path of the JSON output from the value profiler"),
    cl::Hidden, cl::ZeroOrMore, cl::cat(PollyCategory),
    cl::location(polly::PollyValueProfilerInputFilepath), cl::init(""));

static cl::opt<std::string> OutputFilepath(
    "polly-value-profiler-output-filepath",
    cl::desc("file path of the JSON output from the value profiler"),
    cl::Hidden, cl::init(""), cl::ZeroOrMore, cl::cat(PollyCategory));

static cl::list<std::string> OnlyFunctions(
    "polly-value-profiler-load-only-func",
    cl::desc("Only load values from the value profiler for these functions"
             "Multiple regexes can be comma separated. "
             "Value prpfiling will run on all functions that match "
             "ANY of the regexes provided."),
    cl::ZeroOrMore, cl::CommaSeparated, cl::cat(PollyCategory));


#define DEBUG_TYPE "polly-value-profiler"

static llvm::Function *getOrCreateFunction(Module &M, const char *Name,
                                           llvm::FunctionType *Ty) {
  Function *F = M.getFunction(Name);

  // If F is not available, declare it.
  if (!F) {
    GlobalValue::LinkageTypes Linkage = Function::ExternalLinkage;
    F = Function::Create(Ty, Linkage, Name, &M);
  }

  return F;
}

namespace polly {

bool isValueProfilerSaveEnabled() {
    return OutputFilepath != "";
}

static bool doesStringMatchAnyRegex(StringRef Str,
                                    const cl::list<std::string> &RegexList) {
  for (auto RegexStr : RegexList) {
    Regex R(RegexStr);

    std::string Err;
    if (!R.isValid(Err))
      report_fatal_error("invalid regex given as input to polly: " + Err, true);

    if (R.match(Str))
      return true;
  }
  return false;
}

bool isValueProfilerLoadEnabledForFunction(std::string Name) {
    bool AllowedByOnlyFunctions = [Name]() {
        if (OnlyFunctions.size() == 0) return true;
        return doesStringMatchAnyRegex(Name, OnlyFunctions);
    }();

    if (!AllowedByOnlyFunctions) return false;


    std::map<std::string, uint64_t> m = getConstantValuesFromProfile();
    for(auto it: m) {
        if (it.first.find(Name) != std::string::npos) {
            return true;
        }
    }
    return false;
}
llvm::Function *getOrCreateVpProfileValueProto(llvm::Module &M) {
  PollyIRBuilder Builder(M.getContext());
  return getOrCreateFunction(
      M, "vp_profile_value",
      FunctionType::get(
          Builder.getVoidTy(),
          {Builder.getInt8Ty()->getPointerTo(), Builder.getInt64Ty()},
          /*isVarArg=*/false));
}

using HistogramTy =std::map<uint64_t, uint64_t>;


// Uncached version.
std::map<std::string, HistogramTy> getHistogramFromProfile_() {
    std::ifstream file(PollyValueProfilerInputFilepath);
    std::string rawinput((std::istreambuf_iterator<char>(file)),
            std::istreambuf_iterator<char>());

    if (rawinput == "") {
        errs() << "VALUEPROFILER: unable to read data, loading empty profile input...\n";
        return {};
        // assert(rawinput != "" && "unable to read data from input file");
    }

  Json::Reader reader;
  Json::Value root;

  bool parsingSuccessful = reader.parse(rawinput, root);
  if (!parsingSuccessful) {
    errs() << "unable to parse json from file: "
           << polly::PollyValueProfilerInputFilepath << "\n";
    report_fatal_error("unable to parse JSON for value profiler input.\n");
  }

  std::map<std::string, HistogramTy> nameToHistogram;

  for(unsigned i = 0; i < root.size(); i++) {
      // TODO: make this the iterator.
      Json::Value j = root[i];

      std::string name = j["name"].asString();
      Json::Value jsonHistogram = j["histogram"];

      bool isValidHistogram = true;
      std::map<uint64_t, uint64_t> histogram;
      for(unsigned i = 0; i < jsonHistogram.size(); i++) {
          Json::Value jsonValue = jsonHistogram[i]["value"];
          Json::Value jsonFrequency = jsonHistogram[i]["frequency"];

          // TODO: understand why the fuck this even happens.
          if (jsonValue.isDouble()){
              isValidHistogram = false;
              errs() << __LINE__ << ":name: " << name << "\n";
              errs() << " :value:" << jsonValue.asDouble();
              break;
          }

          if (jsonFrequency.isDouble()) {
              isValidHistogram = false;
              errs() << __LINE__ << ":name: " << name << "\n";
              errs() << " :frequency:" << jsonFrequency.asDouble();
              break;
          }

          histogram[jsonValue.asUInt()] = jsonFrequency.asUInt();


      }
      if (isValidHistogram)
          nameToHistogram[name] = histogram;
  }

  return nameToHistogram;

} // end getConstantValuesFromProfile



std::map<std::string, HistogramTy> getHistogramFromProfileCached() {
    static std::map<std::string, HistogramTy> hist;
    static bool LOADED_HIST = false;

    if (!LOADED_HIST) {
        hist = getHistogramFromProfile_();
        LOADED_HIST = true;
    }

    return hist;
}

std::map<std::string, uint64_t> getConstantValuesFromProfile() {
  static std::map<std::string, HistogramTy> nameToHistogram = getHistogramFromProfileCached();
  static std::map<std::string, uint64_t> nameToConstantValue;

  if (nameToConstantValue.size() == 0) {
      errs() << __PRETTY_FUNCTION__  << "\n";

      for(auto it: nameToHistogram) {
          const std::string name = it.first;
          const HistogramTy hist = it.second;
          assert(hist.size() > 0 && "empty histogram!");
          errs() << "\tconsidering " << name << "\n";
          if (hist.size() != 1) continue;

          // the constant value is the LHS (value) of the first (and only) value in the histogram.
          const uint64_t constantVal = hist.begin()->first;
          nameToConstantValue[name] = constantVal;
          errs() << "\t\tconstant: " << name << " = " << constantVal << "\n";
      }
      errs() << "---\n";
  }
  else {
      errs() << "using cached value profile data\n";
  }

  return nameToConstantValue;

}
} // namespace polly
namespace {

static llvm::Function *getOrCreateVpDumpValuesProto(Module &M) {
  PollyIRBuilder Builder(M.getContext());
  return getOrCreateFunction(
      M, "vp_dump_values",
      FunctionType::get(Builder.getVoidTy(),
                        Builder.getInt8Ty()->getPointerTo(),
                        /*isVarArg=*/false));
}

void createDestructor(Module &M) {
  PollyIRBuilder Builder(M.getContext());

  Function *Dump = getOrCreateVpDumpValuesProto(M);

  FunctionType *FTy =
      FunctionType::get(Builder.getVoidTy(), {}, /*isVarArg=*/false);
  Function *Destructor = Function::Create(FTy, Function::ExternalLinkage,
                                          "dtor_vp_dump_values", &M);
  BasicBlock *Entry = BasicBlock::Create(M.getContext(), "entry", Destructor);
  Builder.SetInsertPoint(Entry);

  Value *FilenameStr = Builder.CreateGlobalStringPtr(OutputFilepath);

  Builder.CreateCall(Dump, FilenameStr);
  Builder.CreateRetVoid();
  appendToGlobalDtors(M, Destructor, /*Priority=*/0);
}

void readInput() {
    std::map<std::string, HistogramTy> nameToHistogram = polly::getHistogramFromProfileCached();

    DEBUG(
    dbgs() << "Profiler data:\n";
    for(auto n2hist: nameToHistogram) {
        dbgs() << "name: " << n2hist.first << "\n";
        for(auto val2freq: n2hist.second) {
            dbgs() << "\t val(" << val2freq.first << ") : freq(" << val2freq.second << ")\n";
        }
        
    });
}

class ValueProfiler : public ModulePass {
public:
  static char ID;

  ValueProfiler() : ModulePass(ID) {}
  virtual bool runOnModule(Module &M) {
    // assert(OutputFilepath != "" &&
    //        "value profiler pass scheduled without setting output file path");
    if (PollyValueProfilerInputFilepath != "")
      readInput();

    if (OutputFilepath != "")
      createDestructor(M);

    assert((OutputFilepath != "" || PollyValueProfilerInputFilepath != "") &&
           "value profiler run with neither input nor output pass scheduled");
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

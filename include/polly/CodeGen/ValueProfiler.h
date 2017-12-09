//===---- ValueProfiling.h - Infrastructure for Value Profiling -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Take a scop created by ScopInfo and map it to GPU code using the ppcg
// GPU mapping strategy.
//
//===----------------------------------------------------------------------===//

#ifndef POLLY_VALUEPROFILER_H
#define POLLY_VALUEPROFILER_H
#include <string>
#include <map>

namespace llvm {
class Module;
class Function;
} // namespace llvm

namespace polly {
extern std::string PollyValueProfilerInputFilepath;
llvm::Function *getOrCreateVpProfileValueProto(llvm::Module &M);
std::map<std::string, uint64_t>  getConstantValuesFromProfile();
bool isValueProfilerSaveEnabled(); 
bool isValueProfilerLoadEnabledForFunction(std::string Name);
} // namespace polly

#endif // POLLY_VALUEPROFILER_H

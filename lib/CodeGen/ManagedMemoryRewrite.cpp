//===------ ManagedMemoryRewrite.cpp - Rewrite global & malloc'd memory. ---===//
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

#include "polly/CodeGen/PPCGCodeGeneration.h"
#include "polly/CodeGen/CodeGeneration.h"
#include "polly/CodeGen/IslAst.h"
#include "polly/CodeGen/IslNodeBuilder.h"
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
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
namespace {
    class ManagedMemoryRewritePass : public ModulePass {
        public:
            static char ID;
            GPUArch Architecture;
            GPURuntime Runtime;
            ManagedMemoryRewritePass() : ModulePass(ID) {}
            virtual bool runOnModule(Module &M) {
                errs() << "====Running on module:===="; M.dump();
                return false;
            }
    };

}
char ManagedMemoryRewritePass::ID = 42;

Pass *polly::createManagedMemoryRewritePassPass(GPUArch Arch, GPURuntime Runtime) {
  ManagedMemoryRewritePass *pass = new ManagedMemoryRewritePass();
  pass->Runtime = Runtime;
  pass->Architecture = Arch;
  return pass;
}

INITIALIZE_PASS_BEGIN(ManagedMemoryRewritePass, "polly-managed-memory-rewrite",
                    "Polly - Rewrite all allocations in heap & data section to managed memory", false, false)
//INITIALIZE_PASS_DEPENDENCY(PPCGCodeGeneration);
//INITIALIZE_PASS_DEPENDENCY(DependenceInfo);
//INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass);
//INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
//INITIALIZE_PASS_DEPENDENCY(RegionInfoPass);
//INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass);
//INITIALIZE_PASS_DEPENDENCY(ScopDetectionWrapperPass);
INITIALIZE_PASS_END(ManagedMemoryRewritePass, "polly-managed-memory-rewrite",
                    "Polly - Rewrite all allocations in heap & data section to managed memory", false, false)

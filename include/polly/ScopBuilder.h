//===- polly/ScopBuilder.h --------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Create a polyhedral description for a static control flow region.
//
// The pass creates a polyhedral description of the Scops detected by the SCoP
// detection derived from their LLVM-IR code.
//
//===----------------------------------------------------------------------===//

#ifndef POLLY_SCOPBUILDER_H
#define POLLY_SCOPBUILDER_H

#include "polly/ScopInfo.h"
#include "polly/Support/ScopHelper.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallVector.h"
#include <algorithm>
#include <memory>
#include <utility>

namespace llvm {

class AssumptionCache;
class BasicBlock;
class DataLayout;
class DominatorTree;
class Instruction;
class LoopInfo;
class PassRegistry;
class PHINode;
class Region;
class ScalarEvolution;
class SCEV;
class Type;
class Value;

void initializeScopInfoRegionPassPass(PassRegistry &);
void initializeScopInfoWrapperPassPass(PassRegistry &);
} // end namespace llvm

namespace polly {

class ScopDetection;

/// Command line switch whether to model read-only accesses.
extern bool ModelReadOnlyScalars;

/// Build the Polly IR (Scop and ScopStmt) on a Region.
class ScopBuilder {
  /// The AliasAnalysis to build AliasSetTracker.
  AliasAnalysis &AA;

  /// Target data for element size computing.
  const DataLayout &DL;

  /// DominatorTree to reason about guaranteed execution.
  DominatorTree &DT;

  /// LoopInfo for information about loops.
  LoopInfo &LI;

  /// Valid Regions for Scop
  ScopDetection &SD;

  /// The ScalarEvolution to help building Scop.
  ScalarEvolution &SE;

  /// Set of instructions that might read any memory location.
  SmallVector<std::pair<ScopStmt *, Instruction *>, 16> GlobalReads;

  /// Set of all accessed array base pointers.
  SmallSetVector<Value *, 16> ArrayBasePointers;

  // The Scop
  std::unique_ptr<Scop> scop;

  // Methods for pattern matching against Fortran code generated by dragonegg.
  // @{

  /// Try to match for the descriptor of a Fortran array whose allocation
  /// is not visible. That is, we can see the load/store into the memory, but
  /// we don't actually know where the memory is allocated. If ALLOCATE had been
  /// called on the Fortran array, then we will see the lowered malloc() call.
  /// If not, this is dubbed as an "invisible allocation".
  ///
  /// "<descriptor>" is the descriptor of the Fortran array.
  ///
  /// Pattern match for "@descriptor":
  ///  1. %mem = load double*, double** bitcast (%"struct.array1_real(kind=8)"*
  ///    <descriptor> to double**), align 32
  ///
  ///  2. [%slot = getelementptr inbounds i8, i8* %mem, i64 <index>]
  ///  2 is optional because if you are writing to the 0th index, you don't
  ///     need a GEP.
  ///
  ///  3.1 store/load <memtype> <val>, <memtype>* %slot
  ///  3.2 store/load <memtype> <val>, <memtype>* %mem
  ///
  /// @see polly::MemoryAccess, polly::ScopArrayInfo
  ///
  /// @note assumes -polly-canonicalize has been run.
  ///
  /// @param Inst The LoadInst/StoreInst that accesses the memory.
  ///
  /// @returns Reference to <descriptor> on success, nullptr on failure.
  Value *findFADAllocationInvisible(MemAccInst Inst);

  /// Try to match for the descriptor of a Fortran array whose allocation
  /// call is visible. When we have a Fortran array, we try to look for a
  /// Fortran array where we can see the lowered ALLOCATE call. ALLOCATE
  /// is materialized as a malloc(...) which we pattern match for.
  ///
  /// Pattern match for "%untypedmem":
  ///  1. %untypedmem = i8* @malloc(...)
  ///
  ///  2. %typedmem = bitcast i8* %untypedmem to <memtype>
  ///
  ///  3. [%slot = getelementptr inbounds i8, i8* %typedmem, i64 <index>]
  ///  3 is optional because if you are writing to the 0th index, you don't
  ///     need a GEP.
  ///
  ///  4.1 store/load <memtype> <val>, <memtype>* %slot, align 8
  ///  4.2 store/load <memtype> <val>, <memtype>* %mem, align 8
  ///
  /// @see polly::MemoryAccess, polly::ScopArrayInfo
  ///
  /// @note assumes -polly-canonicalize has been run.
  ///
  /// @param Inst The LoadInst/StoreInst that accesses the memory.
  ///
  /// @returns Reference to %untypedmem on success, nullptr on failure.
  Value *findFADAllocationVisible(MemAccInst Inst);

  // @}

  // Build the SCoP for Region @p R.
  void buildScop(Region &R, AssumptionCache &AC,
                 OptimizationRemarkEmitter &ORE);

  /// Try to build a multi-dimensional fixed sized MemoryAccess from the
  /// Load/Store instruction.
  ///
  /// @param Inst       The Load/Store instruction that access the memory
  /// @param Stmt       The parent statement of the instruction
  ///
  /// @returns True if the access could be built, False otherwise.
  bool buildAccessMultiDimFixed(MemAccInst Inst, ScopStmt *Stmt);

  /// Try to build a multi-dimensional parametric sized MemoryAccess.
  ///        from the Load/Store instruction.
  ///
  /// @param Inst       The Load/Store instruction that access the memory
  /// @param Stmt       The parent statement of the instruction
  ///
  /// @returns True if the access could be built, False otherwise.
  bool buildAccessMultiDimParam(MemAccInst Inst, ScopStmt *Stmt);

  /// Try to build a MemoryAccess for a memory intrinsic.
  ///
  /// @param Inst       The instruction that access the memory
  /// @param Stmt       The parent statement of the instruction
  ///
  /// @returns True if the access could be built, False otherwise.
  bool buildAccessMemIntrinsic(MemAccInst Inst, ScopStmt *Stmt);

  /// Try to build a MemoryAccess for a call instruction.
  ///
  /// @param Inst       The call instruction that access the memory
  /// @param Stmt       The parent statement of the instruction
  ///
  /// @returns True if the access could be built, False otherwise.
  bool buildAccessCallInst(MemAccInst Inst, ScopStmt *Stmt);

  /// Build a single-dimensional parametric sized MemoryAccess
  ///        from the Load/Store instruction.
  ///
  /// @param Inst       The Load/Store instruction that access the memory
  /// @param Stmt       The parent statement of the instruction
  void buildAccessSingleDim(MemAccInst Inst, ScopStmt *Stmt);

  /// Build an instance of MemoryAccess from the Load/Store instruction.
  ///
  /// @param Inst       The Load/Store instruction that access the memory
  /// @param Stmt       The parent statement of the instruction
  void buildMemoryAccess(MemAccInst Inst, ScopStmt *Stmt);

  /// Analyze and extract the cross-BB scalar dependences (or, dataflow
  /// dependencies) of an instruction.
  ///
  /// @param UserStmt The statement @p Inst resides in.
  /// @param Inst     The instruction to be analyzed.
  void buildScalarDependences(ScopStmt *UserStmt, Instruction *Inst);

  /// Build the escaping dependences for @p Inst.
  ///
  /// Search for uses of the llvm::Value defined by @p Inst that are not
  /// within the SCoP. If there is such use, add a SCALAR WRITE such that
  /// it is available after the SCoP as escaping value.
  ///
  /// @param Inst The instruction to be analyzed.
  void buildEscapingDependences(Instruction *Inst);

  /// Create MemoryAccesses for the given PHI node in the given region.
  ///
  /// @param PHIStmt            The statement @p PHI resides in.
  /// @param PHI                The PHI node to be handled
  /// @param NonAffineSubRegion The non affine sub-region @p PHI is in.
  /// @param IsExitBlock        Flag to indicate that @p PHI is in the exit BB.
  void buildPHIAccesses(ScopStmt *PHIStmt, PHINode *PHI,
                        Region *NonAffineSubRegion, bool IsExitBlock = false);

  /// Build the access functions for the subregion @p SR.
  void buildAccessFunctions();

  /// Should an instruction be modeled in a ScopStmt.
  ///
  /// @param Inst The instruction to check.
  /// @param L    The loop in which context the instruction is looked at.
  ///
  /// @returns True if the instruction should be modeled.
  bool shouldModelInst(Instruction *Inst, Loop *L);

  /// Create one or more ScopStmts for @p BB.
  ///
  /// Consecutive instructions are associated to the same statement until a
  /// separator is found.
  void buildSequentialBlockStmts(BasicBlock *BB, bool SplitOnStore = false);

  /// Create one or more ScopStmts for @p BB using equivalence classes.
  ///
  /// Instructions of a basic block that belong to the same equivalence class
  /// are added to the same statement.
  void buildEqivClassBlockStmts(BasicBlock *BB);

  /// Create ScopStmt for all BBs and non-affine subregions of @p SR.
  ///
  /// @param SR A subregion of @p R.
  ///
  /// Some of the statements might be optimized away later when they do not
  /// access any memory and thus have no effect.
  void buildStmts(Region &SR);

  /// Build the access functions for the statement @p Stmt in or represented by
  /// @p BB.
  ///
  /// @param Stmt               Statement to add MemoryAccesses to.
  /// @param BB                 A basic block in @p R.
  /// @param NonAffineSubRegion The non affine sub-region @p BB is in.
  void buildAccessFunctions(ScopStmt *Stmt, BasicBlock &BB,
                            Region *NonAffineSubRegion = nullptr);

  /// Create a new MemoryAccess object and add it to #AccFuncMap.
  ///
  /// @param Stmt        The statement where the access takes place.
  /// @param Inst        The instruction doing the access. It is not necessarily
  ///                    inside @p BB.
  /// @param AccType     The kind of access.
  /// @param BaseAddress The accessed array's base address.
  /// @param ElemType    The type of the accessed array elements.
  /// @param Affine      Whether all subscripts are affine expressions.
  /// @param AccessValue Value read or written.
  /// @param Subscripts  Access subscripts per dimension.
  /// @param Sizes       The array dimension's sizes.
  /// @param Kind        The kind of memory accessed.
  ///
  /// @return The created MemoryAccess, or nullptr if the access is not within
  ///         the SCoP.
  MemoryAccess *addMemoryAccess(ScopStmt *Stmt, Instruction *Inst,
                                MemoryAccess::AccessType AccType,
                                Value *BaseAddress, Type *ElemType, bool Affine,
                                Value *AccessValue,
                                ArrayRef<const SCEV *> Subscripts,
                                ShapeInfo Shape, MemoryKind Kind);

  /// Create a MemoryAccess that represents either a LoadInst or
  /// StoreInst.
  ///
  /// @param Stmt        The statement to add the MemoryAccess to.
  /// @param MemAccInst  The LoadInst or StoreInst.
  /// @param AccType     The kind of access.
  /// @param BaseAddress The accessed array's base address.
  /// @param ElemType    The type of the accessed array elements.
  /// @param IsAffine    Whether all subscripts are affine expressions.
  /// @param Subscripts  Access subscripts per dimension.
  /// @param Sizes       The array dimension's sizes.
  /// @param AccessValue Value read or written.
  ///
  /// @see MemoryKind
  void addArrayAccess(ScopStmt *Stmt, MemAccInst MemAccInst,
                      MemoryAccess::AccessType AccType, Value *BaseAddress,
                      Type *ElemType, bool IsAffine,
                      ArrayRef<const SCEV *> Subscripts,
                      ShapeInfo Shape, Value *AccessValue);

  /// Create a MemoryAccess for writing an llvm::Instruction.
  ///
  /// The access will be created at the position of @p Inst.
  ///
  /// @param Inst The instruction to be written.
  ///
  /// @see ensureValueRead()
  /// @see MemoryKind
  void ensureValueWrite(Instruction *Inst);

  /// Ensure an llvm::Value is available in the BB's statement, creating a
  /// MemoryAccess for reloading it if necessary.
  ///
  /// @param V        The value expected to be loaded.
  /// @param UserStmt Where to reload the value.
  ///
  /// @see ensureValueStore()
  /// @see MemoryKind
  void ensureValueRead(Value *V, ScopStmt *UserStmt);

  /// Create a write MemoryAccess for the incoming block of a phi node.
  ///
  /// Each of the incoming blocks write their incoming value to be picked in the
  /// phi's block.
  ///
  /// @param PHI           PHINode under consideration.
  /// @param IncomingStmt  The statement to add the MemoryAccess to.
  /// @param IncomingBlock Some predecessor block.
  /// @param IncomingValue @p PHI's value when coming from @p IncomingBlock.
  /// @param IsExitBlock   When true, uses the .s2a alloca instead of the
  ///                      .phiops one. Required for values escaping through a
  ///                      PHINode in the SCoP region's exit block.
  /// @see addPHIReadAccess()
  /// @see MemoryKind
  void ensurePHIWrite(PHINode *PHI, ScopStmt *IncomintStmt,
                      BasicBlock *IncomingBlock, Value *IncomingValue,
                      bool IsExitBlock);

  /// Create a MemoryAccess for reading the value of a phi.
  ///
  /// The modeling assumes that all incoming blocks write their incoming value
  /// to the same location. Thus, this access will read the incoming block's
  /// value as instructed by this @p PHI.
  ///
  /// @param PHIStmt Statement @p PHI resides in.
  /// @param PHI     PHINode under consideration; the READ access will be added
  ///                here.
  ///
  /// @see ensurePHIWrite()
  /// @see MemoryKind
  void addPHIReadAccess(ScopStmt *PHIStmt, PHINode *PHI);

  /// Build the domain of @p Stmt.
  void buildDomain(ScopStmt &Stmt);

  /// Fill NestLoops with loops surrounding @p Stmt.
  void collectSurroundingLoops(ScopStmt &Stmt);

  /// Check for reductions in @p Stmt.
  ///
  /// Iterate over all store memory accesses and check for valid binary
  /// reduction like chains. For all candidates we check if they have the same
  /// base address and there are no other accesses which overlap with them. The
  /// base address check rules out impossible reductions candidates early. The
  /// overlap check, together with the "only one user" check in
  /// collectCandidateReductionLoads, guarantees that none of the intermediate
  /// results will escape during execution of the loop nest. We basically check
  /// here that no other memory access can access the same memory as the
  /// potential reduction.
  void checkForReductions(ScopStmt &Stmt);

  /// Collect loads which might form a reduction chain with @p StoreMA.
  ///
  /// Check if the stored value for @p StoreMA is a binary operator with one or
  /// two loads as operands. If the binary operand is commutative & associative,
  /// used only once (by @p StoreMA) and its load operands are also used only
  /// once, we have found a possible reduction chain. It starts at an operand
  /// load and includes the binary operator and @p StoreMA.
  ///
  /// Note: We allow only one use to ensure the load and binary operator cannot
  ///       escape this block or into any other store except @p StoreMA.
  void collectCandidateReductionLoads(MemoryAccess *StoreMA,
                                      SmallVectorImpl<MemoryAccess *> &Loads);

  /// Build the access relation of all memory accesses of @p Stmt.
  void buildAccessRelations(ScopStmt &Stmt);

public:
  explicit ScopBuilder(Region *R, AssumptionCache &AC, AliasAnalysis &AA,
                       const DataLayout &DL, DominatorTree &DT, LoopInfo &LI,
                       ScopDetection &SD, ScalarEvolution &SE,
                       OptimizationRemarkEmitter &ORE);
  ScopBuilder(const ScopBuilder &) = delete;
  ScopBuilder &operator=(const ScopBuilder &) = delete;
  ~ScopBuilder() = default;

  /// Try to build the Polly IR of static control part on the current
  /// SESE-Region.
  ///
  /// @return Give up the ownership of the scop object or static control part
  ///         for the region
  std::unique_ptr<Scop> getScop() { return std::move(scop); }
};
} // end namespace polly

#endif // POLLY_SCOPBUILDER_H

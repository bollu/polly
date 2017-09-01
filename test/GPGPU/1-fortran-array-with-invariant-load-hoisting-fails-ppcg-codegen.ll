; RUN: opt -S \
; RUN:     -polly-detect-fortran-arrays \
; RUN:     -polly-process-unprofitable \
; RUN:     -polly-codegen-ppcg \
; RUN:     -polly-invariant-load-hoisting \
; RUN:     -polly-use-llvm-names \
; RUN:     -polly-use-llvm-names \
; RUN:     < %s

; ModuleID = '1-fortran-array-with-invariant-load-hoisting-fails-ppcg-codegen.ll'
source_filename = "linked.inlined.s"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

; REPLACE THIS WITH A NAME LIKE "arr.ty" AND THIS STARTS WORKING. WTF. WHAT THE
; ACTUAL FUCK.
%"struct.array1_real(kind=8)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }

@global_arr = external unnamed_addr global %"struct.array1_real(kind=8)", align 32

; Function Attrs: nounwind uwtable
define void @__src_sso_MOD_sso(i32* noalias %ipstart, i32* noalias %ipend) unnamed_addr #0 {
entry:
  br label %loop.prepare


loop.prepare:                                              ; preds = %"6", %"3.preheader"
  %start.val = load i32, i32* %ipstart, align 4
  %end.val = load i32, i32* %ipend, align 4
  %should.loop = icmp sgt i32 %start.val, %end.val
  br i1 %should.loop, label %for.exit, label %for.body


for.body:                                              ; preds = %for.body, %"4.preheader"
  %i = phi i32 [ %i.next, %for.body ], [ %start.val, %loop.prepare ]
  %i.sext = sext i32 %i to i64
  %zfis.memory = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @global_arr to double**), align 32
  %zfis.offset = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @global_arr, i64 0, i32 1), align 8
  %zfis.idx = add i64 %zfis.offset, %i.sext
  %zfis.slot = getelementptr double, double* %zfis.memory, i64 %zfis.idx
  store double 1.0, double* %zfis.slot, align 8

  %zfis.memory2 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @global_arr to double**), align 32
  %zfis.offset2 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @global_arr, i64 0, i32 1), align 8
  %zfis.idx2 = add i64 %zfis.offset2, %i.sext
  %zfis.slot2 = getelementptr double, double* %zfis.memory2, i64 %zfis.idx2
  %zfis.val = load double, double* %zfis.slot2, align 8

  %should.loopexit = icmp eq i32 %i, %end.val
  %i.next = add i32 %i, 1
  br i1 %should.loopexit, label %for.exit, label %for.body

for.exit:                                     ; preds = %for.body
  ret void
}

attributes #0 = { nounwind uwtable }

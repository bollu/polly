; MODULE m
; IMPLICIT NONE
;
; CONTAINS
;     SUBROUTINE f(arr, bloop, eloop, arrinp)
;         INTEGER, INTENT(IN) :: &
;             bloop, eloop
;         REAL, INTENT(IN) :: &
;             arrinp(bloop:eloop)
;         REAL, INTENT(INOUT) :: &
;             arr(bloop:eloop)
;         INTEGER :: &
;             i
;
;         DO i=bloop, eloop
;               arr(i) = arrinp(i)
;         END DO
;     END SUBROUTINE f
; END MODULE m

; RUN: opt %loadPolly \
; RUN: -polly-invariant-load-hoisting \
; RUN: -polly-detect-fortran-arrays \
; RUN: -polly-codegen-ppcg \
; RUN: -polly-acc-codegen-managed-memory \
; RUN: -polly-acc-fail-on-verify-module-failure \
; RUN: -debug-only=polly-codegen-ppcg,polly-scops \
; RUN: -S \
; RUN: -pass-remarks=polly \
; RUN: < %s

; ModuleID = 'm.ll'
source_filename = "m.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

; Function Attrs: nounwind uwtable
define void @__m_MOD_f([0 x float]* noalias %arr, i32* noalias %bloop, i32* noalias %eloop, [0 x float]* noalias %arrinp) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = load i32, i32* %bloop, align 4
  %1 = sext i32 %0 to i64
  %2 = load i32, i32* %eloop, align 4
  %3 = sub nsw i64 0, %1
  %4 = icmp sgt i32 %0, %2
  br i1 %4, label %return, label %"3.preheader"

"3.preheader":                                    ; preds = %entry.split
  br label %"3"

"3":                                              ; preds = %"3", %"3.preheader"
  %5 = phi i32 [ %15, %"3" ], [ %0, %"3.preheader" ]
  %6 = sext i32 %5 to i64
  %7 = tail call i64 @_gfortran_polly_array_index_1(i64 %3, i64 1, i64 %6) #1
  %8 = tail call i64 @_gfortran_polly_array_index_1(i64 %3, i64 1, i64 %6) #1
  %9 = getelementptr [0 x float], [0 x float]* %arrinp, i64 0, i64 %8
  %10 = bitcast float* %9 to i32*
  %11 = load i32, i32* %10, align 4
  %12 = getelementptr [0 x float], [0 x float]* %arr, i64 0, i64 %7
  %13 = bitcast float* %12 to i32*
  store i32 %11, i32* %13, align 4
  %14 = icmp eq i32 %5, %2
  %15 = add i32 %5, 1
  br i1 %14, label %return.loopexit, label %"3"

return.loopexit:                                  ; preds = %"3"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

declare i64 @_gfortran_polly_array_index_1(i64, i64, i64) #2

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind }
attributes #2 = { readnone }


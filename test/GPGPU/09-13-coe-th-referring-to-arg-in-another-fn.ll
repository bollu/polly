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

; MODULE m
; IMPLICIT NONE
;
; CONTAINS
;     SUBROUTINE f(arr, arr_input, bloop, eloop)
;         INTEGER, INTENT(IN) :: &
;             bloop, eloop
;         REAL, INTENT(IN) :: &
;             arr_input(bloop:eloop)
;         REAL, INTENT(INOUT) :: &
;             arr(bloop:eloop)
;         INTEGER :: &
;             i
;         REAL :: &
;             cmp_val, final_val
;
;         DO i=bloop, eloop
;             cmp_val = arr_input(i)
;             IF (cmp_val .LT. 42) THEN
;                 final_val = EXP (cmp_val)
;             ELSE
;                 final_val = 100
;             END IF
;
;             arr(i)=final_val
;         END DO
;     END SUBROUTINE f
; END MODULE m;

; Error:
;     verifyModule Error:
;     Referring to an argument in another function!
;       %p_1 = getelementptr [0 x float], [0 x float]* %arr_input, i64 0, i64 %p_
;     VerifyModule failed.

target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

; Function Attrs: nounwind uwtable
define void @__m_MOD_f([0 x float]* noalias %arr, [0 x float]* noalias %arr_input, i32* noalias %bloop, i32* noalias %eloop) unnamed_addr #0 {
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

"3":                                              ; preds = %"6", %"3.preheader"
  %5 = phi i32 [ %16, %"6" ], [ %0, %"3.preheader" ]
  %6 = sext i32 %5 to i64
  %7 = tail call i64 @_gfortran_polly_array_index_1(i64 %3, i64 1, i64 %6) #2
  %8 = getelementptr [0 x float], [0 x float]* %arr_input, i64 0, i64 %7
  %9 = load float, float* %8, align 4
  %10 = fcmp olt float %9, 4.2e+02
  br i1 %10, label %"4", label %"6"

"4":                                              ; preds = %"3"
  %11 = tail call float @expf(float %9) #1
  br label %"6"

"6":                                              ; preds = %"3", %"4"
  %12 = phi float [ %11, %"4" ], [ 1.000000e+02, %"3" ]
  %13 = tail call i64 @_gfortran_polly_array_index_1(i64 %3, i64 1, i64 %6) #2
  %14 = getelementptr [0 x float], [0 x float]* %arr, i64 0, i64 %13
  store float %12, float* %14, align 4
  %15 = icmp eq i32 %5, %2
  %16 = add i32 %5, 1
  br i1 %15, label %return.loopexit, label %"3"

return.loopexit:                                  ; preds = %"6"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

declare i64 @_gfortran_polly_array_index_1(i64, i64, i64) #2

; Function Attrs: nounwind readnone
declare float @expf(float) #1

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind readnone }
attributes #2 = { nounwind }
attributes #2 = { readnone }

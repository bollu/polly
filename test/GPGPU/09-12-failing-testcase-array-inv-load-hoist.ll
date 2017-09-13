; RUN: opt %loadPolly \
; RUN: -polly-invariant-load-hoisting \
; RUN: -polly-detect-fortran-arrays \
; RUN: -polly-codegen-ppcg \
; RUN: -polly-acc-codegen-managed-memory \
; RUN: -polly-acc-fail-on-verify-module-failure \
; RUN: -debug-only=polly-codegen-ppcg,polly-scops \
; RUN: -S \
; RUN: -pass-remarks=polly

; CHECK: foo
; CONTAINS
;     SUBROUTINE f(arr, bloop, eloop, barr, earr, arrinp, arrinp2)
;         INTEGER, INTENT(IN) :: &
;             bloop, eloop, barr, earr
;         REAL, INTENT(IN) :: &
;             ! arrinp(barr:earr, ki3sd:ki3ed), &
;             arrinp(barr:earr, barr:earr), &
;             arrinp2(barr:earr, barr:earr)
;         REAL, INTENT(INOUT) :: &
;             arr(barr:earr)
;         INTEGER :: &
;             i, i3
;         REAL :: &
;             coeff
;
;         DO i=bloop, eloop
;               arr(i) = arrinp(0, 0) + arrinp2(i, 0)
;         END DO
;     END SUBROUTINE f
; END MODULE m

; ModuleID = 'm.ll'
source_filename = "m.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

; Function Attrs: nounwind uwtable
define void @__m_MOD_f([0 x float]* noalias %arr, i32* noalias %bloop, i32* noalias %eloop, i32* noalias %barr, i32* noalias %earr, [0 x float]* noalias %arrinp, [0 x float]* noalias %arrinp2) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = load i32, i32* %barr, align 4
  %1 = sext i32 %0 to i64
  %2 = load i32, i32* %earr, align 4
  %3 = sext i32 %2 to i64
  %4 = sub nsw i64 1, %1
  %5 = add nsw i64 %4, %3
  %6 = icmp sgt i64 %5, 0
  %7 = select i1 %6, i64 %5, i64 0
  %8 = sub nsw i64 0, %1
  %9 = mul i64 %7, %1
  %10 = sub i64 %8, %9
  %11 = load i32, i32* %bloop, align 4
  %12 = load i32, i32* %eloop, align 4
  %13 = icmp sgt i32 %11, %12
  br i1 %13, label %return, label %"3.preheader"

"3.preheader":                                    ; preds = %entry.split
  br label %"3"

"3":                                              ; preds = %"3", %"3.preheader"
  %14 = phi i32 [ %26, %"3" ], [ %11, %"3.preheader" ]
  %15 = sext i32 %14 to i64
  %16 = tail call i64 @_gfortran_polly_array_index_1(i64 %8, i64 1, i64 %15) #1
  %17 = tail call i64 @_gfortran_polly_array_index_2(i64 %10, i64 %7, i64 1, i64 0, i64 0) #1
  %18 = getelementptr [0 x float], [0 x float]* %arrinp, i64 0, i64 %17
  %19 = load float, float* %18, align 4
  %20 = tail call i64 @_gfortran_polly_array_index_2(i64 %10, i64 %7, i64 1, i64 0, i64 %15) #1
  %21 = getelementptr [0 x float], [0 x float]* %arrinp2, i64 0, i64 %20
  %22 = load float, float* %21, align 4
  %23 = fadd float %19, %22
  %24 = getelementptr [0 x float], [0 x float]* %arr, i64 0, i64 %16
  store float %23, float* %24, align 4
  %25 = icmp eq i32 %14, %12
  %26 = add i32 %14, 1
  br i1 %25, label %return.loopexit, label %"3"

return.loopexit:                                  ; preds = %"3"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

declare i64 @_gfortran_polly_array_index_1(i64, i64, i64) #2

declare i64 @_gfortran_polly_array_index_2(i64, i64, i64, i64, i64) #2

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind }
attributes #2 = { readnone }

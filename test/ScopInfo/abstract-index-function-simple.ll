; RUN: opt %loadPolly -polly-scops -analyze -polly-allow-nonaffine \
; RUN: -polly-ignore-aliasing -polly-use-llvm-names \
; RUN: -polly-invariant-load-hoisting -debug-only=polly-scops < %s 2>&1 | FileCheck %s


; Check that we detect the scop.
; CHECK:    Function: __m_MOD_f
; CHECK:    Region: %"3"---%return
; CHECK:    Max Loop Depth:  2

; Check that we generate pw_affs for strides.
; CHECK:    Arrays (Bounds as pw_affs) {
; CHECK-NEXT:        float* MemRef___m_MOD_g_arr[*]; // Element size 8
; CHECK-NEXT:        float MemRef1(Strides)[ [0_param_stride_size] -> { [] -> [(0_param_stride_size)] } ][ [1_param_stride_size] -> { [] -> [(1_param_stride_size)] } ]; [BasePtrOrigin: MemRef___m_MOD_g_arr] // Element size 4
; CHECK-NEXT:    }

; MODULE m
; IMPLICIT NONE
;     ! REAL :: &
;     !     g_arr_const_5_5(5, 5)
;     REAL, ALLOCATABLE :: &
;         g_arr(:,:)
;
; CONTAINS
;     SUBROUTINE f()
;         INTEGER :: &
;             i, j
;
;         REAL :: &
;             coeff
;
;         DO i=1,3
;            DO j=1,3
;               g_arr(i*5, j*2) = 100
;            END DO
;         END DO
;     END SUBROUTINE f
; END MODULE m
; ModuleID = 'm.ll'
source_filename = "m.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array2_real(kind=4)" = type { i8*, i64, i64, [2 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }

@__m_MOD_g_arr = unnamed_addr global %"struct.array2_real(kind=4)" zeroinitializer, align 32

; Function Attrs: nounwind uwtable
define void @__m_MOD_f() unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %"3"

"3":                                              ; preds = %"6", %entry.split
  %indvars.iv1 = phi i64 [ %indvars.iv.next2, %"6" ], [ 1, %entry.split ]
  br label %"4"

"4":                                              ; preds = %"4", %"3"
  %indvars.iv = phi i64 [ %indvars.iv.next, %"4" ], [ 1, %"3" ]
  %0 = load float*, float** bitcast (%"struct.array2_real(kind=4)"* @__m_MOD_g_arr to float**), align 32
  %1 = mul nuw nsw i64 %indvars.iv1, 5
  %2 = shl i64 %indvars.iv, 1
  %3 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 3, i64 1, i32 0), align 8
  %4 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 1), align 8
  %5 = tail call i64 @_gfortran_polly_array_index_2(i64 %4, i64 %3, i64 1, i64 %2, i64 %1) #1
  %6 = getelementptr float, float* %0, i64 %5
  store float 1.000000e+02, float* %6, align 4
  %7 = icmp eq i64 %indvars.iv, 3
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br i1 %7, label %"6", label %"4"

"6":                                              ; preds = %"4"
  %8 = icmp eq i64 %indvars.iv1, 3
  %indvars.iv.next2 = add nuw nsw i64 %indvars.iv1, 1
  br i1 %8, label %return, label %"3"

return:                                           ; preds = %"6"
  ret void
}

declare i64 @_gfortran_polly_array_index_2(i64, i64, i64, i64, i64) #2

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind }
attributes #2 = { readnone }

; RUN: opt -S -polly-detect-fortran-arrays -analyze -polly-process-unprofitable \
; RUN: -polly-remarks-minimal -polly-canonicalize -polly-scops \
; RUN: -polly-dependences -polly-canonicalize \
; RUN: -polly-allow-nonaffine -polly-ignore-aliasing \
; RUN: -polly-invariant-load-hoisting < %s| FileCheck %s

; ModuleID = 'simple-nonaffine-read.bc'
; ModuleID = 'simple-nonaffine-read.bc'

; This testcase is the corresponding LLVM for func:
; PROGRAM main
;     INTEGER, DIMENSION(1) :: xs

;     CALL testfunc(xs, 10)
; CONTAINS
;     SUBROUTINE func(xs, n)
;         IMPLICIT NONE
;         INTEGER, DIMENSION(:), INTENT(INOUT) :: xs
;         INTEGER, INTENT(IN) :: n
;         INTEGER :: i

;         DO i = 1, n
;             xs(i) = 1
;         END DO

;     END SUBROUTINE func
; END PROGRAM

target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_integer(kind=4)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array1_integer(kind=4).0" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }

; Function Attrs: nounwind uwtable
define internal void @testfunc(%"struct.array1_integer(kind=4)"* noalias %xs, i32* noalias %n) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = getelementptr inbounds %"struct.array1_integer(kind=4)", %"struct.array1_integer(kind=4)"* %xs, i64 0, i32 3, i64 0, i32 0
  %1 = load i64, i64* %0, align 8
  %2 = icmp eq i64 %1, 0
  %3 = select i1 %2, i64 1, i64 %1
  %4 = bitcast %"struct.array1_integer(kind=4)"* %xs to i32**
  %5 = load i32*, i32** %4, align 8
  %6 = load i32, i32* %n, align 4
  %7 = icmp sgt i32 %6, 0
  br i1 %7, label %"6.preheader", label %return

"6.preheader":                                    ; preds = %entry.split
  br label %"6"

"6":                                              ; preds = %"6", %"6.preheader"
  %8 = phi i32 [ %14, %"6" ], [ 1, %"6.preheader" ]
  %9 = sext i32 %8 to i64
  %10 = mul i64 %3, %9
  %11 = sub i64 %10, %3
  %12 = getelementptr i32, i32* %5, i64 %11
  store i32 1, i32* %12, align 4
  %13 = icmp eq i32 %8, %6
  %14 = add i32 %8, 1
  br i1 %13, label %return.loopexit, label %"6"

return.loopexit:                                  ; preds = %"6"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

; CHECK: ReadAccess :=	[Reduction Type: NONE] [Fortran array descriptor: xs] [Scalar: 0]            

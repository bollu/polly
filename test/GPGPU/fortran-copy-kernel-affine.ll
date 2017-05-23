; RUN: opt -analyze %loadPolly -polly-allow-nonaffine -polly-ignore-aliasing -polly-scops -polly-detect-fortran-arrays \
; RUN:  < %s | FileCheck  %s -check-prefix=SCOPS

; RUN: opt %loadPolly -polly-allow-nonaffine -polly-ignore-aliasing -polly-detect-fortran-arrays -polly-codegen-ppcg -polly-acc-dump-code \
; RUN: -disable-output < %s | FileCheck -check-prefix=CODE %s

; REQUIRES: pollyacc

; Check that Fortran arrays are detected.
; SCOPS:      ReadAccess :=	[Reduction Type: NONE] [Fortran array descriptor: xs] [Scalar: 0]
; SCOPS-NEXT:     [p_0_loaded_from_n, MemRef0_fortranarr_size, MemRef1_fortranarr_size] -> { Stmt_9[i0] -> MemRef0[o0] };
; SCOPS-NEXT: MayWriteAccess :=	[Reduction Type: NONE] [Fortran array descriptor: ys] [Scalar: 0]
; SCOPS-NEXT:     [p_0_loaded_from_n, MemRef0_fortranarr_size, MemRef1_fortranarr_size] -> { Stmt_9[i0] -> MemRef1[o0] };

; Check that we generate CUDA calls
; CODE:      Code
; CODE-NEXT: ====
; CODE-NEXT: # host
; CODE-NEXT: {
; CODE-NEXT:   if (MemRef0_fortranarr_size >= 1)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(dev_MemRef0, MemRef0, (MemRef0_fortranarr_size) * sizeof(i32), cudaMemcpyHostToDevice));
; CODE-NEXT:   if (MemRef1_fortranarr_size >= 1)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(dev_MemRef1, MemRef1, (MemRef1_fortranarr_size) * sizeof(i32), cudaMemcpyHostToDevice));
; CODE-NEXT:   for (int c0 = 0; c0 < p_0_loaded_from_n; c0 += 1)
; CODE-NEXT:     {
; CODE-NEXT:       dim3 k0_dimBlock;
; CODE-NEXT:       dim3 k0_dimGrid;
; CODE-NEXT:       kernel0 <<<k0_dimGrid, k0_dimBlock>>> (dev_MemRef0, dev_MemRef1, p_0_loaded_from_n, MemRef0_fortranarr_size, MemRef1_fortranarr_size, c0);
; CODE-NEXT:       cudaCheckKernel();
; CODE-NEXT:     }
; CODE:        if (MemRef1_fortranarr_size >= 1)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(MemRef1, dev_MemRef1, (MemRef1_fortranarr_size) * sizeof(i32), cudaMemcpyDeviceToHost));
; CODE-NEXT: }

; PROGRAM main
;     INTEGER, DIMENSION(100) :: xs
;     INTEGER, DIMENSION(100) :: ys
; 
;     DO i = 1, 100
;         xs (i) = i
;         ys(i) = 0
;     END DO
; 
;     CALL copy(xs, ys, 10)
; 
;     PRINT *, ys
; CONTAINS
;     SUBROUTINE copy(xs, ys, n)
;         IMPLICIT NONE
;         INTEGER, DIMENSION(:), INTENT(INOUT) :: xs, ys
;         INTEGER, INTENT(IN) :: n
;         INTEGER :: i
; 
;         DO i = 1, n
;             ys(i * i) = xs(i * i)
;         END DO
; 
;     END SUBROUTINE copy
; END PROGRAM

target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_integer(kind=4)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array1_integer(kind=4).0" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.__st_parameter_dt = type { %struct.__st_parameter_common, i64, i64*, i64*, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, [256 x i8], i32*, i64, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, [4 x i8] }
%struct.__st_parameter_common = type { i32, i32, i8*, i32, i32, i8*, i32* }
%"struct.array1_integer(kind=4).1" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%"struct.array1_integer(kind=4).2" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%"struct.array1_integer(kind=4).3" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%"struct.array1_integer(kind=4).4" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }

@.cst = private constant [12 x i8] c"program.f90\00", align 8
@0 = internal constant i32 10
@options.14.1603 = internal constant [8 x i32] [i32 68, i32 511, i32 0, i32 0, i32 0, i32 1, i32 0, i32 1], align 32

define internal void @copy.1550(%"struct.array1_integer(kind=4)"* noalias %xs, %"struct.array1_integer(kind=4).0"* noalias %ys, i32* noalias %n) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = getelementptr inbounds %"struct.array1_integer(kind=4).0", %"struct.array1_integer(kind=4).0"* %ys, i64 0, i32 3, i64 0, i32 0
  %1 = load i64, i64* %0, align 8
  %2 = icmp eq i64 %1, 0
  %3 = select i1 %2, i64 1, i64 %1
  %4 = bitcast %"struct.array1_integer(kind=4).0"* %ys to i32**
  %5 = load i32*, i32** %4, align 8
  %6 = getelementptr inbounds %"struct.array1_integer(kind=4)", %"struct.array1_integer(kind=4)"* %xs, i64 0, i32 3, i64 0, i32 0
  %7 = load i64, i64* %6, align 8
  %8 = icmp eq i64 %7, 0
  %. = select i1 %8, i64 1, i64 %7
  %9 = bitcast %"struct.array1_integer(kind=4)"* %xs to i32**
  %10 = load i32*, i32** %9, align 8
  %11 = load i32, i32* %n, align 4
  %12 = icmp sgt i32 %11, 0
  br i1 %12, label %"9.preheader", label %return

"9.preheader":                                    ; preds = %entry.split
  br label %"9"

"9":                                              ; preds = %"9.preheader", %"9"
  %13 = phi i32 [ %24, %"9" ], [ 1, %"9.preheader" ]
  %14 = sext i32 %13 to i64
  %15 = mul i64 %3, %14
  %16 = sub i64 %15, %3
  %17 = sext i32 %13 to i64
  %18 = mul i64 %., %17
  %19 = sub i64 %18, %.
  %20 = getelementptr i32, i32* %10, i64 %19
  %21 = load i32, i32* %20, align 4
  %22 = getelementptr i32, i32* %5, i64 %16
  store i32 %21, i32* %22, align 4
  %23 = icmp eq i32 %13, %11
  %24 = add i32 %13, 1
  br i1 %23, label %return.loopexit, label %"9"

return.loopexit:                                  ; preds = %"9"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

declare void @_gfortran_set_args(i32, i8**)

declare void @_gfortran_set_options(i32, i32*)

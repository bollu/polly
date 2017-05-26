; RUN: opt -analyze %loadPolly -polly-allow-nonaffine -polly-ignore-aliasing -polly-scops -polly-detect-fortran-arrays \
; RUN:  < %s | FileCheck  %s -check-prefix=SCOPS

; RUN: opt %loadPolly -polly-allow-nonaffine -polly-ignore-aliasing -polly-detect-fortran-arrays -polly-codegen-ppcg -polly-acc-dump-code \
; RUN: -disable-output < %s | FileCheck -check-prefix=CODE %s

; REQUIRES: pollyacc

; Check that Fortran arrays are detected.
; SCOPS:       ReadAccess :=	[Reduction Type: NONE] [Fortran array descriptor: xs] [Scalar: 0]
; SCOPS-NEXT:     [tmp11, tmp7, p_2, tmp1, p_4, MemRef_tmp10_fortranarr_size, MemRef_tmp5_fortranarr_size] -> { Stmt_9[i0] -> MemRef_tmp10[1 + i0, -p_2] };
; SCOPS-NEXT: MustWriteAccess :=	[Reduction Type: NONE] [Fortran array descriptor: ys] [Scalar: 0]
; SCOPS-NEXT:     [tmp11, tmp7, p_2, tmp1, p_4, MemRef_tmp10_fortranarr_size, MemRef_tmp5_fortranarr_size] -> { Stmt_9[i0] -> MemRef_tmp5[1 + i0, -p_4] };

; Check that we generate CUDA calls
; CODE:      Code
; CODE-NEXT: ====
; CODE-NEXT: # host
; CODE-NEXT: if (tmp11 >= 1) {
; CODE-NEXT:   if (tmp7 >= 1 && MemRef_tmp10_fortranarr_size >= 2)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(dev_MemRef_tmp10, MemRef_tmp10, (MemRef_tmp10_fortranarr_size >= tmp11 + 1 ? tmp11 + 1 : MemRef_tmp10_fortranarr_size) * (tmp7) * sizeof(i32), cudaMemcpyHostToDevice));
; CODE-NEXT:   if (tmp1 >= 1 && MemRef_tmp5_fortranarr_size >= 2)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(dev_MemRef_tmp5, MemRef_tmp5, (MemRef_tmp5_fortranarr_size >= tmp11 + 1 ? tmp11 + 1 : MemRef_tmp5_fortranarr_size) * (tmp1) * sizeof(i32), cudaMemcpyHostToDevice));
; CODE-NEXT:   {
; CODE-NEXT:     dim3 k0_dimBlock(32);
; CODE-NEXT:     dim3 k0_dimGrid(tmp11 >= 1048546 ? 32768 : floord(tmp11 + 31, 32));
; CODE-NEXT:     kernel0 <<<k0_dimGrid, k0_dimBlock>>> (dev_MemRef_tmp10, dev_MemRef_tmp5, tmp11, tmp7, p_2, tmp1, p_4, MemRef_tmp10_fortranarr_size, MemRef_tmp5_fortranarr_size);
; CODE-NEXT:     cudaCheckKernel();
; CODE-NEXT:   }

; CODE:        if (tmp1 >= 1 && MemRef_tmp5_fortranarr_size >= 2)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(MemRef_tmp5, dev_MemRef_tmp5, (MemRef_tmp5_fortranarr_size >= tmp11 + 1 ? tmp11 + 1 : MemRef_tmp5_fortranarr_size) * (tmp1) * sizeof(i32), cudaMemcpyDeviceToHost));
; CODE-NEXT: }
; This is not the exact code that is generated from dragonegg. A non-affine access that is
; created due to error checking is manually made linear.
;
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
;             ys(i) = xs(i)
;         END DO
; 
;     END SUBROUTINE copy
; END PROGRAM


; ModuleID = 'test/GPGPU/fortran-copy-kernel-affine.ll'
source_filename = "test/GPGPU/fortran-copy-kernel-affine.ll"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_integer(kind=4)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array1_integer(kind=4).0" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }

@.cst = private constant [12 x i8] c"program.f90\00", align 8
@0 = internal constant i32 10
@options.14.1603 = internal constant [8 x i32] [i32 68, i32 511, i32 0, i32 0, i32 0, i32 1, i32 0, i32 1], align 32

define internal void @copy.1550(%"struct.array1_integer(kind=4)"* noalias %xs, %"struct.array1_integer(kind=4).0"* noalias %ys, i32* noalias %n) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %tmp = getelementptr inbounds %"struct.array1_integer(kind=4).0", %"struct.array1_integer(kind=4).0"* %ys, i64 0, i32 3, i64 0, i32 0
  %tmp1 = load i64, i64* %tmp, align 8
  %tmp2 = icmp eq i64 %tmp1, 0
  %tmp3 = select i1 %tmp2, i64 1, i64 %tmp1
  %tmp4 = bitcast %"struct.array1_integer(kind=4).0"* %ys to i32**
  %tmp5 = load i32*, i32** %tmp4, align 8
  %tmp6 = getelementptr inbounds %"struct.array1_integer(kind=4)", %"struct.array1_integer(kind=4)"* %xs, i64 0, i32 3, i64 0, i32 0
  %tmp7 = load i64, i64* %tmp6, align 8
  %tmp8 = icmp eq i64 %tmp7, 0
  %. = select i1 %tmp8, i64 1, i64 %tmp7
  %tmp9 = bitcast %"struct.array1_integer(kind=4)"* %xs to i32**
  %tmp10 = load i32*, i32** %tmp9, align 8
  %tmp11 = load i32, i32* %n, align 4
  %tmp12 = icmp sgt i32 %tmp11, 0
  br i1 %tmp12, label %"9.preheader", label %return

"9.preheader":                                    ; preds = %entry.split
  br label %"9"

"9":                                              ; preds = %"9", %"9.preheader"
  %tmp13 = phi i32 [ %tmp24, %"9" ], [ 1, %"9.preheader" ]
  %tmp14 = sext i32 %tmp13 to i64
  ; replace %tmp3 with % tmp1
  ; %tmp15 = mul i64 %tmp3, %tmp14
  %tmp15 = mul i64 %tmp1, %tmp14
  
  %tmp16 = sub i64 %tmp15, %tmp3
  %tmp17 = sext i32 %tmp13 to i64
  ; replace %. with %tmp7
  ; %tmp18 = mul i64 %., %tmp17
  %tmp18 = mul i64 %tmp7, %tmp17
  
  %tmp19 = sub i64 %tmp18, %.
  %tmp20 = getelementptr i32, i32* %tmp10, i64 %tmp19
  %tmp21 = load i32, i32* %tmp20, align 4
  %tmp22 = getelementptr i32, i32* %tmp5, i64 %tmp16
  store i32 %tmp21, i32* %tmp22, align 4
  %tmp23 = icmp eq i32 %tmp13, %tmp11
  %tmp24 = add i32 %tmp13, 1
  br i1 %tmp23, label %return.loopexit, label %"9"

return.loopexit:                                  ; preds = %"9"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

declare void @_gfortran_set_args(i32, i8**)

declare void @_gfortran_set_options(i32, i32*)

; RUN: opt -analyze %loadPolly -polly-allow-nonaffine -polly-ignore-aliasing -polly-scops -polly-detect-fortran-arrays \
; RUN:  < %s | \
; RUN: FileCheck  %s -check-prefix=SCOPS

; RUN: opt %loadPolly -polly-allow-nonaffine -polly-ignore-aliasing -polly-detect-fortran-arrays -polly-codegen-ppcg -polly-acc-dump-code \
; RUN: -disable-output < %s | \
; RUN: FileCheck -check-prefix=CODE %s

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

; CODE:      if (MemRef1_fortranarr_size >= 1)
; CODE-NEXT:     cudaCheckReturn(cudaMemcpy(MemRef1, dev_MemRef1, (MemRef1_fortranarr_size) * sizeof(i32), cudaMemcpyDeviceToHost));
; CODE-NEXT: }

; CODE:      kernel0
; CODE-NEXT: Stmt_9(c0);

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
; ModuleID = 'program.bc'

; ModuleID = 'program.bc'
source_filename = "program.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_integer(kind=4)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array1_integer(kind=4).0" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%"struct.array1_integer(kind=4).1" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%"struct.array1_integer(kind=4).2" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.__st_parameter_dt = type { %struct.__st_parameter_common, i64, i64*, i64*, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, [256 x i8], i32*, i64, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, [4 x i8] }
%struct.__st_parameter_common = type { i32, i32, i8*, i32, i32, i8*, i32* }
%"struct.array1_integer(kind=4).3" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }

@0 = internal constant i32 10
@.cst = private constant [12 x i8] c"program.f90\00", align 8
@options.12.1603 = internal constant [8 x i32] [i32 68, i32 511, i32 0, i32 0, i32 0, i32 1, i32 0, i32 1], align 32

; Function Attrs: nounwind uwtable
define internal void @copy.1550(%"struct.array1_integer(kind=4)"* noalias %xs, %"struct.array1_integer(kind=4).0"* noalias %ys, i32* noalias %n) #0 {
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

"9":                                              ; preds = %"9", %"9.preheader"
  %13 = phi i32 [ %26, %"9" ], [ 1, %"9.preheader" ]
  %14 = mul i32 %13, %13
  %15 = sext i32 %14 to i64
  %16 = mul i64 %3, %15
  %17 = sub i64 %16, %3
  %18 = mul i32 %13, %13
  %19 = sext i32 %18 to i64
  %20 = mul i64 %., %19
  %21 = sub i64 %20, %.
  %22 = getelementptr i32, i32* %10, i64 %21
  %23 = load i32, i32* %22, align 4
  %24 = getelementptr i32, i32* %5, i64 %17
  store i32 %23, i32* %24, align 4
  %25 = icmp eq i32 %13, %11
  %26 = add i32 %13, 1
  br i1 %25, label %return.loopexit, label %"9"

return.loopexit:                                  ; preds = %"9"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

; Function Attrs: nounwind uwtable
define internal void @MAIN__() #0 {
entry:
  %xs = alloca [100 x i32], align 4
  %ys = alloca [100 x i32], align 4
  %parm.9 = alloca %"struct.array1_integer(kind=4).1", align 8
  %parm.8 = alloca %"struct.array1_integer(kind=4).2", align 8
  %dt_parm.10 = alloca %struct.__st_parameter_dt, align 8
  %parm.11 = alloca %"struct.array1_integer(kind=4).3", align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %"3"

"3":                                              ; preds = %"3", %entry.split
  %indvars.iv = phi i64 [ %indvars.iv.next, %"3" ], [ 1, %entry.split ]
  %0 = add nsw i64 %indvars.iv, -1
  %1 = getelementptr [100 x i32], [100 x i32]* %xs, i64 0, i64 %0
  %2 = trunc i64 %indvars.iv to i32
  store i32 %2, i32* %1, align 4
  %3 = add nsw i64 %indvars.iv, -1
  %4 = getelementptr [100 x i32], [100 x i32]* %ys, i64 0, i64 %3
  store i32 0, i32* %4, align 4
  %5 = icmp eq i64 %indvars.iv, 100
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br i1 %5, label %"5", label %"3"

"5":                                              ; preds = %"3"
  %6 = getelementptr inbounds %"struct.array1_integer(kind=4).2", %"struct.array1_integer(kind=4).2"* %parm.8, i64 0, i32 2
  store i64 265, i64* %6, align 8
  %7 = getelementptr inbounds %"struct.array1_integer(kind=4).2", %"struct.array1_integer(kind=4).2"* %parm.8, i64 0, i32 3, i64 0, i32 1
  store i64 1, i64* %7, align 8
  %8 = getelementptr inbounds %"struct.array1_integer(kind=4).2", %"struct.array1_integer(kind=4).2"* %parm.8, i64 0, i32 3, i64 0, i32 2
  store i64 100, i64* %8, align 8
  %9 = getelementptr inbounds %"struct.array1_integer(kind=4).2", %"struct.array1_integer(kind=4).2"* %parm.8, i64 0, i32 3, i64 0, i32 0
  store i64 1, i64* %9, align 8
  %10 = bitcast %"struct.array1_integer(kind=4).2"* %parm.8 to [100 x i32]**
  store [100 x i32]* %xs, [100 x i32]** %10, align 8
  %11 = getelementptr inbounds %"struct.array1_integer(kind=4).2", %"struct.array1_integer(kind=4).2"* %parm.8, i64 0, i32 1
  store i64 -1, i64* %11, align 8
  %12 = getelementptr inbounds %"struct.array1_integer(kind=4).1", %"struct.array1_integer(kind=4).1"* %parm.9, i64 0, i32 2
  store i64 265, i64* %12, align 8
  %13 = getelementptr inbounds %"struct.array1_integer(kind=4).1", %"struct.array1_integer(kind=4).1"* %parm.9, i64 0, i32 3, i64 0, i32 1
  store i64 1, i64* %13, align 8
  %14 = getelementptr inbounds %"struct.array1_integer(kind=4).1", %"struct.array1_integer(kind=4).1"* %parm.9, i64 0, i32 3, i64 0, i32 2
  store i64 100, i64* %14, align 8
  %15 = getelementptr inbounds %"struct.array1_integer(kind=4).1", %"struct.array1_integer(kind=4).1"* %parm.9, i64 0, i32 3, i64 0, i32 0
  store i64 1, i64* %15, align 8
  %16 = bitcast %"struct.array1_integer(kind=4).1"* %parm.9 to [100 x i32]**
  store [100 x i32]* %ys, [100 x i32]** %16, align 8
  %17 = getelementptr inbounds %"struct.array1_integer(kind=4).1", %"struct.array1_integer(kind=4).1"* %parm.9, i64 0, i32 1
  store i64 -1, i64* %17, align 8
  %18 = bitcast %"struct.array1_integer(kind=4).2"* %parm.8 to %"struct.array1_integer(kind=4)"*
  %19 = bitcast %"struct.array1_integer(kind=4).1"* %parm.9 to %"struct.array1_integer(kind=4).0"*
  call void @copy.1550(%"struct.array1_integer(kind=4)"* nonnull %18, %"struct.array1_integer(kind=4).0"* nonnull %19, i32* nonnull @0) #1
  %20 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.10, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.cst, i64 0, i64 0), i8** %20, align 8
  %21 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.10, i64 0, i32 0, i32 3
  store i32 12, i32* %21, align 8
  %22 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.10, i64 0, i32 0, i32 0
  store i32 128, i32* %22, align 8
  %23 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.10, i64 0, i32 0, i32 1
  store i32 6, i32* %23, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.10) #1
  %24 = getelementptr inbounds %"struct.array1_integer(kind=4).3", %"struct.array1_integer(kind=4).3"* %parm.11, i64 0, i32 2
  store i64 265, i64* %24, align 8
  %25 = getelementptr inbounds %"struct.array1_integer(kind=4).3", %"struct.array1_integer(kind=4).3"* %parm.11, i64 0, i32 3, i64 0, i32 1
  store i64 1, i64* %25, align 8
  %26 = getelementptr inbounds %"struct.array1_integer(kind=4).3", %"struct.array1_integer(kind=4).3"* %parm.11, i64 0, i32 3, i64 0, i32 2
  store i64 100, i64* %26, align 8
  %27 = getelementptr inbounds %"struct.array1_integer(kind=4).3", %"struct.array1_integer(kind=4).3"* %parm.11, i64 0, i32 3, i64 0, i32 0
  store i64 1, i64* %27, align 8
  %28 = bitcast %"struct.array1_integer(kind=4).3"* %parm.11 to [100 x i32]**
  store [100 x i32]* %ys, [100 x i32]** %28, align 8
  %29 = getelementptr inbounds %"struct.array1_integer(kind=4).3", %"struct.array1_integer(kind=4).3"* %parm.11, i64 0, i32 1
  store i64 -1, i64* %29, align 8
  %30 = bitcast %"struct.array1_integer(kind=4).3"* %parm.11 to i8*
  call void @_gfortran_transfer_array_write(%struct.__st_parameter_dt* nonnull %dt_parm.10, i8* nonnull %30, i32 4, i32 0) #1
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.10) #1
  ret void
}

declare void @_gfortran_st_write(%struct.__st_parameter_dt*)

declare void @_gfortran_transfer_array_write(%struct.__st_parameter_dt*, i8*, i32, i32)

declare void @_gfortran_st_write_done(%struct.__st_parameter_dt*)

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  tail call void @_gfortran_set_args(i32 %argc, i8** %argv) #1
  tail call void @_gfortran_set_options(i32 8, i32* getelementptr inbounds ([8 x i32], [8 x i32]* @options.12.1603, i64 0, i64 0)) #1
  tail call void @MAIN__() #0
  ret i32 0
}

declare void @_gfortran_set_args(i32, i8**)

declare void @_gfortran_set_options(i32, i32*)

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind }

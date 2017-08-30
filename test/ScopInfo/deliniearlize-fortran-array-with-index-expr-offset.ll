; RUN: opt %loadPolly -analyze -polly-scops -polly-detect-fortran-arrays \
; RUN: -polly-use-llvm-names \
; RUN: -polly-rtc-max-parameters=1000 \
; RUN: -polly-rtc-max-arrays-per-group=1000 \
; RUN: -polly-ignore-integer-wrapping \
; RUN: -polly-ignore-parameter-bounds \
; RUN: -polly-invariant-load-hoisting \
; RUN: < %s |  FileCheck %s

; CHECK:      Function: __m_MOD_outer
; CHECK-NEXT: Region: %"3"---%return
; CHECK-NEXT: Max Loop Depth:  2

; CHECK: MustWriteAccess :=	[Reduction Type: NONE] [Fortran array descriptor: __m_MOD_global_arr_coeff] [Scalar: 0]
; CHECK-NEXT: [p_1_loaded_from___m_MOD_global_arr_coeff] -> { Stmt_4[i0, i1] -> MemRef1[1 + i0, i1, p_1_loaded_from___m_MOD_global_arr_coeff] };

source_filename = "llvm-link"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"
module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array2_real(kind=4)" = type { i8*, i64, i64, [2 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%struct.__st_parameter_dt = type { %struct.__st_parameter_common, i64, i64*, i64*, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, [256 x i8], i32*, i64, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, [4 x i8] }
%struct.__st_parameter_common = type { i32, i32, i8*, i32, i32, i8*, i32* }

@options.2.1559 = internal constant [8 x i32] [i32 68, i32 511, i32 0, i32 0, i32 0, i32 1, i32 0, i32 1], align 32
@.cst = private constant [12 x i8] c"program.f90\00", align 8
@.cst1 = private constant [11 x i8] c"hello world", align 8
@__m_MOD_global_arr_coeff = global %"struct.array2_real(kind=4)" zeroinitializer, align 32
@.cst.7 = private constant [6 x i8] c"m.f90\00", align 8
@.cst1.8 = private constant [13 x i8] c"ALLOCATING...", align 8

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  tail call void @_gfortran_set_args(i32 %argc, i8** %argv) #2
  tail call void @_gfortran_set_options(i32 8, i32* getelementptr inbounds ([8 x i32], [8 x i32]* @options.2.1559, i64 0, i64 0)) #2
  tail call void @MAIN__() #0
  ret i32 0
}

declare void @_gfortran_set_args(i32, i8**)

declare void @_gfortran_set_options(i32, i32*)

; Function Attrs: nounwind uwtable
define internal void @MAIN__() #0 {
entry:
  %dt_parm.0 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1 = alloca %struct.__st_parameter_dt, align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.cst, i64 0, i64 0), i8** %0, align 8
  %1 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 3
  store i32 5, i32* %1, align 8
  %2 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 0
  store i32 128, i32* %2, align 8
  %3 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 1
  store i32 6, i32* %3, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.0) #2
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.0, i8* getelementptr inbounds ([11 x i8], [11 x i8]* @.cst1, i64 0, i64 0), i32 11) #2
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.0) #2
  call void @__m_MOD_alloc() #2
  call void @__m_MOD_outer() #2
  %4 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.cst, i64 0, i64 0), i8** %4, align 8
  %5 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1, i64 0, i32 0, i32 3
  store i32 10, i32* %5, align 8
  %6 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1, i64 0, i32 0, i32 0
  store i32 128, i32* %6, align 8
  %7 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1, i64 0, i32 0, i32 1
  store i32 6, i32* %7, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1) #2
  call void @_gfortran_transfer_array_write(%struct.__st_parameter_dt* nonnull %dt_parm.1, i8* nonnull bitcast (%"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff to i8*), i32 4, i32 0) #2
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1) #2
  ret void
}

declare void @_gfortran_st_write(%struct.__st_parameter_dt*)

declare void @_gfortran_transfer_character_write(%struct.__st_parameter_dt*, i8*, i32)

declare void @_gfortran_st_write_done(%struct.__st_parameter_dt*)

declare void @_gfortran_transfer_array_write(%struct.__st_parameter_dt*, i8*, i32, i32)

; Function Attrs: nounwind uwtable
define void @__m_MOD_outer() #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %"3"

"3":                                              ; preds = %"6", %entry.split
  %indvars.iv1 = phi i64 [ %indvars.iv.next2, %"6" ], [ 1, %entry.split ]
  br label %"4"

"4":                                              ; preds = %"4", %"3"
  %indvars.iv = phi i64 [ %indvars.iv.next, %"4" ], [ 1, %"3" ]
  %0 = load float*, float** bitcast (%"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff to float**), align 32
  %1 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 1, i32 0), align 8
  %2 = mul i64 %1, %indvars.iv1
  %3 = add i64 %2, %indvars.iv
  %4 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 1), align 8
  %5 = add i64 %3, %4
  %6 = getelementptr float, float* %0, i64 %5
  store float 2.000000e+00, float* %6, align 4
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

; Function Attrs: nounwind uwtable
define void @__m_MOD_alloc() #0 {
entry:
  %dt_parm.0 = alloca %struct.__st_parameter_dt, align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst.7, i64 0, i64 0), i8** %0, align 8
  %1 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 3
  store i32 28, i32* %1, align 8
  %2 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 0
  store i32 128, i32* %2, align 8
  %3 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.0, i64 0, i32 0, i32 1
  store i32 6, i32* %3, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.0) #2
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.0, i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.cst1.8, i64 0, i64 0), i32 13) #2
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.0) #2
  store i64 282, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 2), align 16
  store i64 1, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 0, i32 1), align 8
  store i64 3, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 0, i32 2), align 8
  store i64 1, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 0, i32 0), align 8
  store i64 1, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 1, i32 1), align 8
  store i64 3, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 1, i32 2), align 8
  store i64 3, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 3, i64 1, i32 0), align 8
  %4 = call i64 @llvm.expect.i64(i64 0, i64 0)
  %5 = and i64 %4, 1
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %"4", label %"12"

"4":                                              ; preds = %entry.split
  %7 = load i8*, i8** getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 0), align 32
  %8 = icmp eq i8* %7, null
  br i1 %8, label %"5", label %"8"

"5":                                              ; preds = %"4"
  %9 = call noalias i8* @malloc(i64 36) #2
  br label %"11"

"8":                                              ; preds = %"4"
  call void @free(i8* noalias %7) #2
  %10 = call noalias i8* @malloc(i64 36) #2
  br label %"11"

"11":                                             ; preds = %"8", %"5"
  %11 = phi i8* [ %10, %"8" ], [ %9, %"5" ]
  store i8* %11, i8** getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 0), align 32
  br label %"12"

"12":                                             ; preds = %entry.split, %"11"
  store i64 -4, i64* getelementptr inbounds (%"struct.array2_real(kind=4)", %"struct.array2_real(kind=4)"* @__m_MOD_global_arr_coeff, i64 0, i32 1), align 8
  ret void
}

; Function Attrs: nounwind readnone
declare i64 @llvm.expect.i64(i64, i64) #1

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) #2

; Function Attrs: nounwind
declare void @free(i8*) #2

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind readnone }
attributes #2 = { nounwind }

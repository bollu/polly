; RUN: opt %loadPolly -S -polly-allow-nonaffine \
; RUN: -polly-acc-codegen-managed-memory \
; RUN: -polly-ignore-aliasing -polly-use-llvm-names \
; RUN: -polly-invariant-load-hoisting -polly-codegen-ppcg \
; RUN:  -polly-acc-fail-on-verify-module-failure < %s\
; RUN: | FileCheck %s -check-prefix=HOST-IR
; ModuleID = 'm.ll'

; MODULE m
; IMPLICIT NONE
;     REAL, ALLOCATABLE :: &
;         g_arr(:)
;     !     g_arr_const_5_5(5, 5)
; 
; CONTAINS
;     SUBROUTINE f(arr, b, e)
;         INTEGER, INTENT(IN) :: &
;             b, e
;         REAL, INTENT(INOUT) :: &
;             arr(:)
;         INTEGER :: &
;             i
; 
;         REAL :: &
;             coeff
; 
;         DO i= b,e
;               arr(i) = 7 * i
;         END DO
;     END SUBROUTINE f
; END MODULE m
; 
; PROGRAM p
;     USE m
; 
;     ALLOCATE(g_arr(-1: 1))
; 
;     PRINT *, "calling f()"
;     CALL f (g_arr, -1, 1)
;     PRINT *, "array indeces of interest"
;     DO i=-1, 1
;             PRINT *, "i: ", i
;             PRINT *, g_arr(i)
;     END DO
;     PRINT *, "g_arr after:"
;     PRINT *, g_arr
; END PROGRAM p

source_filename = "m.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_real(kind=4)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array1_real(kind=4).0" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.__st_parameter_dt = type { %struct.__st_parameter_common, i64, i64*, i64*, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, [256 x i8], i32*, i64, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, [4 x i8] }
%struct.__st_parameter_common = type { i32, i32, i8*, i32, i32, i8*, i32* }

@__m_MOD_g_arr = global %"struct.array1_real(kind=4)" zeroinitializer, align 32
@.cst = private constant [67 x i8] c"Integer overflow when calculating the amount of memory to allocate\00", align 64
@.cst1 = private constant [37 x i8] c"Allocation would exceed memory limit\00", align 64
@.cst2 = private constant [6 x i8] c"m.f90\00", align 8
@.cst3 = private constant [11 x i8] c"calling f()", align 8
@0 = internal constant i32 -1
@1 = internal constant i32 1
@.cst4 = private constant [25 x i8] c"array indeces of interest", align 8
@.cst5 = private constant [25 x i8] c"At line 28 of file m.f90\00", align 8
@.cst6 = private constant [55 x i8] c"Attempting to allocate already allocated variable '%s'\00", align 64
@.cst7 = private constant [6 x i8] c"g_arr\00", align 8
@.cst8 = private constant [3 x i8] c"i: ", align 8
@.cst9 = private constant [12 x i8] c"g_arr after:", align 8
@options.13.1599 = internal constant [8 x i32] [i32 68, i32 511, i32 0, i32 0, i32 0, i32 1, i32 0, i32 1], align 32

; Function Attrs: nounwind uwtable
define void @__m_MOD_f(%"struct.array1_real(kind=4).0"* noalias %arr, i32* noalias %b, i32* noalias %e) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = getelementptr inbounds %"struct.array1_real(kind=4).0", %"struct.array1_real(kind=4).0"* %arr, i64 0, i32 3, i64 0, i32 0
  %1 = load i64, i64* %0, align 8
  %2 = icmp eq i64 %1, 0
  %3 = select i1 %2, i64 1, i64 %1
  %4 = bitcast %"struct.array1_real(kind=4).0"* %arr to float**
  %5 = load float*, float** %4, align 8
  %6 = sub i64 0, %3
  %7 = load i32, i32* %b, align 4
  %8 = load i32, i32* %e, align 4
  %9 = icmp sgt i32 %7, %8
  br i1 %9, label %return, label %"6.preheader"

"6.preheader":                                    ; preds = %entry.split
  br label %"6"

"6":                                              ; preds = %"6", %"6.preheader"
  %10 = phi i32 [ %17, %"6" ], [ %7, %"6.preheader" ]
  %11 = sext i32 %10 to i64
  %12 = tail call i64 @_gfortran_polly_array_index_1(i64 %6, i64 %3, i64 %11) #3
  %13 = mul i32 %10, 7
  %14 = sitofp i32 %13 to float
  %15 = getelementptr float, float* %5, i64 %12
  store float %14, float* %15, align 4
  %16 = icmp eq i32 %10, %8
  %17 = add i32 %10, 1
  br i1 %16, label %return.loopexit, label %"6"

return.loopexit:                                  ; preds = %"6"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

declare i64 @_gfortran_polly_array_index_1(i64, i64, i64) #2

; Function Attrs: nounwind uwtable
define internal void @MAIN__() #0 {
entry:
  %i = alloca i32, align 4
  %dt_parm.6 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.7 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.8 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.9 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.11 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.12 = alloca %struct.__st_parameter_dt, align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  store i64 281, i64* getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 2), align 16
  store i64 -1, i64* getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 3, i64 0, i32 1), align 8
  store i64 1, i64* getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 3, i64 0, i32 2), align 8
  store i64 1, i64* getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 3, i64 0, i32 0), align 8
  %0 = tail call i64 @llvm.expect.i64(i64 0, i64 0)
  %1 = and i64 %0, 1
  %2 = icmp eq i64 %1, 0
  br i1 %2, label %"4", label %"3"

"3":                                              ; preds = %entry.split
  tail call void bitcast (void (i8*, ...)* @_gfortran_runtime_error to void (i8*)*)(i8* getelementptr inbounds ([67 x i8], [67 x i8]* @.cst, i64 0, i64 0)) #3
  unreachable

"4":                                              ; preds = %entry.split
  %3 = load i8*, i8** getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 0), align 32
  %4 = icmp eq i8* %3, null
  br i1 %4, label %"5", label %"8"

"5":                                              ; preds = %"4"
  %5 = tail call noalias i8* @malloc(i64 12) #3
  %6 = icmp eq i8* %5, null
  br i1 %6, label %"6", label %"7"

"6":                                              ; preds = %"5"
  tail call void @_gfortran_os_error(i8* getelementptr inbounds ([37 x i8], [37 x i8]* @.cst1, i64 0, i64 0)) #4
  unreachable

"7":                                              ; preds = %"5"
  store i8* %5, i8** getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 0), align 32
  store i64 1, i64* getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 1), align 8
  %7 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.6, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst2, i64 0, i64 0), i8** %7, align 8
  %8 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.6, i64 0, i32 0, i32 3
  store i32 30, i32* %8, align 8
  %9 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.6, i64 0, i32 0, i32 0
  store i32 128, i32* %9, align 8
  %10 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.6, i64 0, i32 0, i32 1
  store i32 6, i32* %10, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.6) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.6, i8* getelementptr inbounds ([11 x i8], [11 x i8]* @.cst3, i64 0, i64 0), i32 11) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.6) #3
  call void @__m_MOD_f(%"struct.array1_real(kind=4).0"* nonnull bitcast (%"struct.array1_real(kind=4)"* @__m_MOD_g_arr to %"struct.array1_real(kind=4).0"*), i32* nonnull @0, i32* nonnull @1) #3
  %11 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.7, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst2, i64 0, i64 0), i8** %11, align 8
  %12 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.7, i64 0, i32 0, i32 3
  store i32 32, i32* %12, align 8
  %13 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.7, i64 0, i32 0, i32 0
  store i32 128, i32* %13, align 8
  %14 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.7, i64 0, i32 0, i32 1
  store i32 6, i32* %14, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.7) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.7, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst4, i64 0, i64 0), i32 25) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.7) #3
  store i32 -1, i32* %i, align 4
  br label %"9"

"8":                                              ; preds = %"4"
  tail call void bitcast (void (i8*, i8*, ...)* @_gfortran_runtime_error_at to void (i8*, i8*, i8*)*)(i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst5, i64 0, i64 0), i8* getelementptr inbounds ([55 x i8], [55 x i8]* @.cst6, i64 0, i64 0), i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst7, i64 0, i64 0)) #3
  unreachable

"9":                                              ; preds = %"9", %"7"
  %15 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.8, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst2, i64 0, i64 0), i8** %15, align 8
  %16 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.8, i64 0, i32 0, i32 3
  store i32 34, i32* %16, align 8
  %17 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.8, i64 0, i32 0, i32 0
  store i32 128, i32* %17, align 8
  %18 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.8, i64 0, i32 0, i32 1
  store i32 6, i32* %18, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.8) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.8, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.cst8, i64 0, i64 0), i32 3) #3
  %19 = bitcast i32* %i to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.8, i8* nonnull %19, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.8) #3
  %20 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.9, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst2, i64 0, i64 0), i8** %20, align 8
  %21 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.9, i64 0, i32 0, i32 3
  store i32 35, i32* %21, align 8
  %22 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.9, i64 0, i32 0, i32 0
  store i32 128, i32* %22, align 8
  %23 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.9, i64 0, i32 0, i32 1
  store i32 6, i32* %23, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.9) #3
  %24 = load float*, float** bitcast (%"struct.array1_real(kind=4)"* @__m_MOD_g_arr to float**), align 32
  %25 = load i32, i32* %i, align 4
  %26 = sext i32 %25 to i64
  %27 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=4)", %"struct.array1_real(kind=4)"* @__m_MOD_g_arr, i64 0, i32 1), align 8
  %28 = call i64 @_gfortran_polly_array_index_1(i64 %27, i64 1, i64 %26) #3
  %29 = getelementptr float, float* %24, i64 %28
  %30 = bitcast float* %29 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.9, i8* %30, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.9) #3
  %31 = load i32, i32* %i, align 4
  %32 = icmp eq i32 %31, 1
  %33 = add i32 %31, 1
  store i32 %33, i32* %i, align 4
  br i1 %32, label %"11", label %"9"

"11":                                             ; preds = %"9"
  %34 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.11, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst2, i64 0, i64 0), i8** %34, align 8
  %35 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.11, i64 0, i32 0, i32 3
  store i32 37, i32* %35, align 8
  %36 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.11, i64 0, i32 0, i32 0
  store i32 128, i32* %36, align 8
  %37 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.11, i64 0, i32 0, i32 1
  store i32 6, i32* %37, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.11) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.11, i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.cst9, i64 0, i64 0), i32 12) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.11) #3
  %38 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.12, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.cst2, i64 0, i64 0), i8** %38, align 8
  %39 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.12, i64 0, i32 0, i32 3
  store i32 38, i32* %39, align 8
  %40 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.12, i64 0, i32 0, i32 0
  store i32 128, i32* %40, align 8
  %41 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.12, i64 0, i32 0, i32 1
  store i32 6, i32* %41, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.12) #3
  call void @_gfortran_transfer_array_write(%struct.__st_parameter_dt* nonnull %dt_parm.12, i8* nonnull bitcast (%"struct.array1_real(kind=4)"* @__m_MOD_g_arr to i8*), i32 4, i32 0) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.12) #3
  ret void
}

; Function Attrs: nounwind readnone
declare i64 @llvm.expect.i64(i64, i64) #1

; Function Attrs: noreturn
declare void @_gfortran_runtime_error(i8*, ...) #2

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) #3

; Function Attrs: noreturn
declare void @_gfortran_os_error(i8*) #2

declare void @_gfortran_st_write(%struct.__st_parameter_dt*)

declare void @_gfortran_transfer_character_write(%struct.__st_parameter_dt*, i8*, i32)

declare void @_gfortran_st_write_done(%struct.__st_parameter_dt*)

; Function Attrs: noreturn
declare void @_gfortran_runtime_error_at(i8*, i8*, ...) #2

declare void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt*, i8*, i32)

declare void @_gfortran_transfer_real_write(%struct.__st_parameter_dt*, i8*, i32)

declare void @_gfortran_transfer_array_write(%struct.__st_parameter_dt*, i8*, i32, i32)

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  tail call void @_gfortran_set_args(i32 %argc, i8** %argv) #3
  tail call void @_gfortran_set_options(i32 8, i32* getelementptr inbounds ([8 x i32], [8 x i32]* @options.13.1599, i64 0, i64 0)) #3
  tail call void @MAIN__() #0
  ret i32 0
}

declare void @_gfortran_set_args(i32, i8**)

declare void @_gfortran_set_options(i32, i32*)

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind readnone }
attributes #2 = { noreturn }
attributes #3 = { nounwind }
attributes #4 = { noreturn nounwind }
attributes #2 = { readnone }

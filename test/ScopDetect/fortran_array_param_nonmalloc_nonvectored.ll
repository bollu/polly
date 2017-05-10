; RUN: opt -S -polly-detect-fortran-arrays -analyze -polly-process-unprofitable \
; RUN: -polly-remarks-minimal -polly-canonicalize -polly-scops \
; RUN: -polly-dependences -polly-canonicalize \
; RUN: -polly-allow-nonaffine -polly-ignore-aliasing \
; RUN: -polly-invariant-load-hoisting < %s| FileCheck %s


; ModuleID = 'simple-nonaffine-read.ll'
source_filename = "simple-nonaffine-read.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_integer(kind=4)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array1_integer(kind=4).0" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }

@options.0.1569 = internal constant [8 x i32] [i32 68, i32 511, i32 0, i32 0, i32 0, i32 1, i32 0, i32 1], align 32

; Function Attrs: nounwind uwtable
define internal void @func.1548(%"struct.array1_integer(kind=4)"* noalias %xs, i32* noalias %s) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  store i32 1, i32* %s, align 4
  %0 = getelementptr inbounds %"struct.array1_integer(kind=4)", %"struct.array1_integer(kind=4)"* %xs, i64 0, i32 3, i64 0, i32 2
  %1 = load i64, i64* %0, align 8
  %2 = getelementptr inbounds %"struct.array1_integer(kind=4)", %"struct.array1_integer(kind=4)"* %xs, i64 0, i32 3, i64 0, i32 1
  %3 = load i64, i64* %2, align 8
  %4 = sub i64 %1, %3
  %5 = add i64 %4, 1
  %6 = icmp sgt i64 %5, 0
  %7 = select i1 %6, i64 %5, i64 0
  %8 = trunc i64 %7 to i32
  %9 = sitofp i32 %8 to float
  %10 = tail call float @sqrtf(float %9) #1
  %11 = fptosi float %10 to i32
  %12 = sitofp i32 %11 to float
  %13 = fcmp ult float %10, %12
  %14 = sext i1 %13 to i32
  %15 = add i32 %14, %11
  %16 = icmp sgt i32 %15, 0
  br i1 %16, label %"6.preheader", label %return

"6.preheader":                                    ; preds = %entry.split
  br label %"6"

"6":                                              ; preds = %"6", %"6.preheader"
  %17 = phi i32 [ %30, %"6" ], [ 1, %"6.preheader" ]
  %18 = load i32, i32* %s, align 4
  %19 = bitcast %"struct.array1_integer(kind=4)"* %xs to i32**
  %20 = load i32*, i32** %19, align 8
  %21 = mul i32 %17, %17
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds %"struct.array1_integer(kind=4)", %"struct.array1_integer(kind=4)"* %xs, i64 0, i32 1
  %24 = load i64, i64* %23, align 8
  %25 = add i64 %24, %22
  %26 = getelementptr i32, i32* %20, i64 %25
  %27 = load i32, i32* %26, align 4
  %28 = mul i32 %27, %18
  store i32 %28, i32* %s, align 4
  %29 = icmp eq i32 %17, %15
  %30 = add i32 %17, 1
  br i1 %29, label %return.loopexit, label %"6"

return.loopexit:                                  ; preds = %"6"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

; Function Attrs: nounwind readnone
declare float @sqrtf(float) #1

; Function Attrs: nounwind uwtable
define internal void @MAIN__() #0 {
entry:
  %arr = alloca %"struct.array1_integer(kind=4).0", align 8
  %s = alloca i32, align 4
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = getelementptr inbounds %"struct.array1_integer(kind=4).0", %"struct.array1_integer(kind=4).0"* %arr, i64 0, i32 0
  store i8* null, i8** %0, align 8
  %1 = bitcast %"struct.array1_integer(kind=4).0"* %arr to %"struct.array1_integer(kind=4)"*
  call void @func.1548(%"struct.array1_integer(kind=4)"* nonnull %1, i32* nonnull %s) #2
  %2 = getelementptr inbounds %"struct.array1_integer(kind=4).0", %"struct.array1_integer(kind=4).0"* %arr, i64 0, i32 0
  %3 = load i8*, i8** %2, align 8
  %4 = icmp eq i8* %3, null
  br i1 %4, label %"4", label %"3"

"3":                                              ; preds = %entry.split
  %5 = getelementptr inbounds %"struct.array1_integer(kind=4).0", %"struct.array1_integer(kind=4).0"* %arr, i64 0, i32 0
  %6 = load i8*, i8** %5, align 8
  call void @free(i8* noalias %6) #2
  br label %"4"

"4":                                              ; preds = %entry.split, %"3"
  %7 = getelementptr inbounds %"struct.array1_integer(kind=4).0", %"struct.array1_integer(kind=4).0"* %arr, i64 0, i32 0
  store i8* null, i8** %7, align 8
  ret void
}

; Function Attrs: nounwind
declare void @free(i8*) #2

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  tail call void @_gfortran_set_args(i32 %argc, i8** %argv) #2
  tail call void @_gfortran_set_options(i32 8, i32* getelementptr inbounds ([8 x i32], [8 x i32]* @options.0.1569, i64 0, i64 0)) #2
  tail call void @MAIN__() #0
  ret i32 0
}

declare void @_gfortran_set_args(i32, i8**)

declare void @_gfortran_set_options(i32, i32*)

attributes #0 = { nounwind uwtable }
attributes #1 = { nounwind readnone }
attributes #2 = { nounwind }

; CHECK: ReadAccess :=	[Reduction Type: NONE] [Fortran array descriptor: xs] [Scalar: 0]            

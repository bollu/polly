; RUN: opt %loadPolly -S -polly-codegen-ppcg \
; RUN: -polly-ignore-parameter-bounds \
; RUN: -polly-invariant-load-hoisting < %s| FileCheck %s -check-prefix=HOST-IR

When we have `-polly-ignore-parameter-bounds`, `Scop::Context` does not contain
all the paramters present in the program.

The construction of the `isl_multi_pw_aff` requires all the indivisual `pw_aff`
to have the same parameter dimensions. To achieve this, we used to realign
every `pw_aff` with `Scop::Context`. However, in conjunction with
`-polly-ignore-parameter-bounds`, this is now incorrect, since `Scop::Context`
does not contain all parameters.

We check that Polly does the right thing in this case and sets up the parameter
dimensions correctly.


; Check that kernel launch is generated in host IR.
; the declare would not be generated unless a call to a kernel exists.
; HOST-IR: declare void @polly_launchKernel(i8*, i32, i32, i32, i32, i32, i8*)

target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nounwind
declare noalias i8* @malloc() #0

; Function Attrs: nounwind uwtable
define void @__meteo_utilities_MOD_calps(i32* noalias %je) unnamed_addr #1 {
entry:
  %0 = select i1 undef, i64 undef, i64 0
  %1 = load i32, i32* %je, align 4
  %2 = sext i32 %1 to i64
  %3 = tail call noalias i8* @malloc() #0
  br label %"13"

"13":                                             ; preds = %"13", %entry
  %4 = phi i64 [ 1, %entry ], [ %10, %"13" ]
  %5 = mul nuw nsw i64 %4, %0
  %6 = add i64 %5, 0
  %7 = add nsw i64 %6, 1
  %8 = bitcast i8* %3 to i32*
  %9 = getelementptr i32, i32* %8, i64 %7
  store i32 1, i32* %9, align 4
  %10 = add nuw nsw i64 %4, 1
  %11 = icmp sgt i64 %10, %2
  br i1 %11, label %"12.17.loopexit_crit_edge", label %"13"

"12.17.loopexit_crit_edge":                       ; preds = %"13"
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { nounwind uwtable }

; RUN: opt -S \
; RUN:     -polly-detect-fortran-arrays \
; RUN:     -polly-process-unprofitable \
; RUN:     -polly-codegen-ppcg \
; RUN:     -polly-invariant-load-hoisting \
; RUN:     -polly-use-llvm-names \
; RUN:     -polly-use-llvm-names \
; RUN:     < %s

; ModuleID = '1-fortran-array-with-invariant-load-hoisting-fails-ppcg-codegen.ll'
source_filename = "linked.inlined.s"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%"struct.array1_real(kind=8)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array2_real(kind=8)" = type { i8*, i64, i64, [2 x %struct.descriptor_dimension] }

@__src_sso_MOD_zfis = external unnamed_addr global %"struct.array1_real(kind=8)", align 32
@__src_sso_MOD_zfi = external unnamed_addr global %"struct.array2_real(kind=8)", align 32

; Function Attrs: nounwind uwtable
define void @__src_sso_MOD_sso(i32* noalias %ipstart, i32* noalias %ipend) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br i1 undef, label %"3.preheader", label %"9.preheader"

"3.preheader":                                    ; preds = %entry.split
  br label %"3"

"3":                                              ; preds = %"6", %"3.preheader"
  %tmp = load i32, i32* %ipstart, align 4
  %tmp1 = load i32, i32* %ipend, align 4
  %tmp2 = icmp sgt i32 %tmp, %tmp1
  br i1 %tmp2, label %"6", label %"4.preheader"

"4.preheader":                                    ; preds = %"3"
  br label %"4"

"4":                                              ; preds = %"4", %"4.preheader"
  %tmp3 = phi i32 [ %tmp20, %"4" ], [ %tmp, %"4.preheader" ]
  %tmp4 = sext i32 %tmp3 to i64
  %tmp5 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis to double**), align 32
  %tmp6 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis, i64 0, i32 1), align 8
  %tmp7 = add i64 %tmp6, %tmp4
  %tmp8 = getelementptr double, double* %tmp5, i64 %tmp7
  store double fmul (double undef, double undef), double* %tmp8, align 8
  %tmp9 = load double*, double** bitcast (%"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi to double**), align 32
  %tmp10 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=8)", %"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi, i64 0, i32 1), align 8
  %tmp11 = add i64 %tmp10, %tmp4
  %tmp12 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis to double**), align 32
  %tmp13 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis, i64 0, i32 1), align 8
  %tmp14 = add i64 %tmp13, %tmp4
  %tmp15 = getelementptr double, double* %tmp12, i64 %tmp14
  %tmp16 = load double, double* %tmp15, align 8
  %tmp17 = fsub double undef, %tmp16
  %tmp18 = getelementptr double, double* %tmp9, i64 %tmp11
  store double %tmp17, double* %tmp18, align 8
  %tmp19 = icmp eq i32 %tmp3, %tmp1
  %tmp20 = add i32 %tmp3, 1
  br i1 %tmp19, label %"6.loopexit", label %"4"

"6.loopexit":                                     ; preds = %"4"
  br label %"6"

"6":                                              ; preds = %"6.loopexit", %"3"
  br i1 true, label %"51.preheader.loopexit", label %"3"

"9.preheader":                                    ; preds = %entry.split
  br label %"9"

"9":                                              ; preds = %"9", %"9.preheader"
  br i1 true, label %"51.preheader.loopexit6", label %"9"

"51.preheader.loopexit":                          ; preds = %"6"
  br label %"51.preheader"

"51.preheader.loopexit6":                         ; preds = %"9"
  br label %"51.preheader"

"51.preheader":                                   ; preds = %"51.preheader.loopexit6", %"51.preheader.loopexit"
  br label %"51"

"51":                                             ; preds = %"51", %"51.preheader"
  br i1 true, label %return, label %"51"

return:                                           ; preds = %"51"
  ret void
}

attributes #0 = { nounwind uwtable }

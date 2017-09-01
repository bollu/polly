; RUN: opt -S \
; RUN:     -polly-detect-fortran-arrays \
; RUN:     -polly-process-unprofitable \
; RUN:     -polly-codegen-ppcg \
; RUN:     -polly-invariant-load-hoisting \
; RUN:     -polly-use-llvm-names \
; RUN:     -polly-use-llvm-names \
; RUN:     < %s

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
define void @__src_sso_MOD_sso(i32* noalias %nproma, i32* noalias %ke, i32* noalias %ke1, i32* noalias %ipstart, i32* noalias %ipend, [0 x double]* noalias %ppf, [0 x double]* noalias %pph, [0 x double]* noalias %pfif, [0 x double]* noalias %pt, [0 x double]* noalias %pu, [0 x double]* noalias %pv, [0 x double]* noalias %hsurf, [0 x double]* noalias %psso_stdh, [0 x double]* noalias %psso_gamma, [0 x double]* noalias %psso_theta, [0 x double]* noalias %psso_sigma, double* noalias %pdt, i32* noalias %knstep, i32* noalias %ldebug, [0 x double]* noalias %pdu_sso, [0 x double]* noalias %pdv_sso, [0 x double]* noalias %pdt_sso, [0 x double]* noalias %pustr_sso, [0 x double]* noalias %pvstr_sso, [0 x double]* noalias %pvdis_sso) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br i1 undef, label %"3.preheader", label %"9.preheader"

"3.preheader":                                    ; preds = %entry.split
  br label %"3"

"3":                                              ; preds = %"6", %"3.preheader"
  %0 = load i32, i32* %ipstart, align 4
  %1 = load i32, i32* %ipend, align 4
  %2 = icmp sgt i32 %0, %1
  br i1 %2, label %"6", label %"4.preheader"

"4.preheader":                                    ; preds = %"3"
  br label %"4"

"4":                                              ; preds = %"4", %"4.preheader"
  %3 = phi i32 [ %20, %"4" ], [ %0, %"4.preheader" ]
  %4 = sext i32 %3 to i64
  %5 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis to double**), align 32
  %6 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis, i64 0, i32 1), align 8
  %7 = add i64 %6, %4
  %8 = getelementptr double, double* %5, i64 %7
  store double fmul (double undef, double undef), double* %8, align 8
  %9 = load double*, double** bitcast (%"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi to double**), align 32
  %10 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=8)", %"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi, i64 0, i32 1), align 8
  %11 = add i64 %10, %4
  %12 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis to double**), align 32
  %13 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis, i64 0, i32 1), align 8
  %14 = add i64 %13, %4
  %15 = getelementptr double, double* %12, i64 %14
  %16 = load double, double* %15, align 8
  %17 = fsub double undef, %16
  %18 = getelementptr double, double* %9, i64 %11
  store double %17, double* %18, align 8
  %19 = icmp eq i32 %3, %1
  %20 = add i32 %3, 1
  br i1 %19, label %"6.loopexit", label %"4"

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

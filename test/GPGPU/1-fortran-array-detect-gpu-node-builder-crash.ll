; RUN: opt -S \
; RUN:     -polly-detect-fortran-arrays \
; RUN:     -polly-process-unprofitable \
; RUN:      -polly-rewrite-byref-params -polly-canonicalize \
; RUN:      -polly-codegen-ppcg \
; RUN:      -polly-invariant-load-hoisting \
; RUN:      -polly-precise-inbounds \
; RUN:      -polly-acc-use-shared \
; RUN:      -polly-acc-use-private -polly-use-llvm-names \
; RUN:      -polly-overflow-tracking=never \
; RUN:      -polly-acc-libdevice=libdevice.ll \
; RUN:      -polly-acc-rewrite-managed-memory \
; RUN:      -polly-ignore-integer-wrapping \
; RUN:      -polly-ignore-inbounds \
; RUN:      -polly-ignore-parameter-bounds \
; RUN:      -polly-use-llvm-names \
; RUN:      -polly-ignore-func=__utilities_MOD_tautsp3d \
; RUN:      -polly-ignore-func=__utilities_MOD_horizontal_filtering  \
; RUN:      -polly-ignore-func=".*timing_tools_MOD.*" \
; RUN:      -polly-ignore-func=__src_block_fields_MOD_init_copy_list \
; RUN:      -polly-ignore-func=__src_block_fields_MOD_reset_copy_flags \
; RUN:      -polly-ignore-func=__src_allocation_MOD_allocate_fields \
; RUN:      -polly-ignore-func=_src_physics_MOD_test_physics \
; RUN:      -polly-ignore-func=__utilities_MOD_tautsp2d \
; RUN:      -polly-ignore-func=__m_dump_MOD_init_dump_block \
; RUN:      -polly-ignore-func=__utilities_MOD_smooth9 \
; RUN:      -polly-acc-mincompute=0 \
; RUN:      -debug-only=polly-codegen-ppcg \
; RUN:      -polly-remarks-minimal \
; RUN:      -polly-rtc-max-parameters=9000000 \
; RUN:      -polly-rtc-max-arrays-per-group=10000 < %s

%"struct.array1_real(kind=8)" = type { i8*, i64, i64, [1 x %struct.descriptor_dimension] }
%struct.descriptor_dimension = type { i64, i64, i64 }
%"struct.array2_real(kind=8)" = type { i8*, i64, i64, [2 x %struct.descriptor_dimension] }
@__src_sso_MOD_zfis = external unnamed_addr global %"struct.array1_real(kind=8)", align 32
@__src_sso_MOD_zfi = external unnamed_addr global %"struct.array2_real(kind=8)", align 32

; ModuleID = 'bugpoint-reduced-simplified.bc'
source_filename = "linked.inlined.s"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

; Function Attrs: nounwind uwtable
define void @__src_sso_MOD_sso(i32* noalias %nproma, i32* noalias %ke, i32* noalias %ke1, i32* noalias %ipstart, i32* noalias %ipend, [0 x double]* noalias %ppf, [0 x double]* noalias %pph, [0 x double]* noalias %pfif, [0 x double]* noalias %pt, [0 x double]* noalias %pu, [0 x double]* noalias %pv, [0 x double]* noalias %hsurf, [0 x double]* noalias %psso_stdh, [0 x double]* noalias %psso_gamma, [0 x double]* noalias %psso_theta, [0 x double]* noalias %psso_sigma, double* noalias %pdt, i32* noalias %knstep, i32* noalias %ldebug, [0 x double]* noalias %pdu_sso, [0 x double]* noalias %pdv_sso, [0 x double]* noalias %pdt_sso, [0 x double]* noalias %pustr_sso, [0 x double]* noalias %pvstr_sso, [0 x double]* noalias %pvdis_sso) unnamed_addr #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br i1 undef, label %"3.preheader", label %"8"

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
  %3 = phi i32 [ %24, %"4" ], [ %0, %"4.preheader" ]
  %4 = sext i32 %3 to i64
  %5 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis to double**), align 32
  %6 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis, i64 0, i32 1), align 8
  %7 = add i64 %6, %4
  %8 = fmul double undef, undef
  %9 = getelementptr double, double* %5, i64 %7
  store double %8, double* %9, align 8
  %10 = load double*, double** bitcast (%"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi to double**), align 32
  %11 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=8)", %"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi, i64 0, i32 3, i64 1, i32 0), align 8
  %12 = mul i64 %11, undef
  %13 = add i64 %12, %4
  %14 = load i64, i64* getelementptr inbounds (%"struct.array2_real(kind=8)", %"struct.array2_real(kind=8)"* @__src_sso_MOD_zfi, i64 0, i32 1), align 8
  %15 = add i64 %13, %14
  %16 = load double*, double** bitcast (%"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis to double**), align 32
  %17 = load i64, i64* getelementptr inbounds (%"struct.array1_real(kind=8)", %"struct.array1_real(kind=8)"* @__src_sso_MOD_zfis, i64 0, i32 1), align 8
  %18 = add i64 %17, %4
  %19 = getelementptr double, double* %16, i64 %18
  %20 = load double, double* %19, align 8
  %21 = fsub double undef, %20
  %22 = getelementptr double, double* %10, i64 %15
  store double %21, double* %22, align 8
  %23 = icmp eq i32 %3, %1
  %24 = add i32 %3, 1
  br i1 %23, label %"6.loopexit", label %"4"

"6.loopexit":                                     ; preds = %"4"
  br label %"6"

"6":                                              ; preds = %"6.loopexit", %"3"
  br i1 undef, label %"8.loopexit", label %"3"

"8.loopexit":                                     ; preds = %"6"
  br label %"8"

"8":                                              ; preds = %"8.loopexit", %entry.split
  br i1 undef, label %"14", label %"9.preheader"

"9.preheader":                                    ; preds = %"8"
  br label %"9"

"9":                                              ; preds = %"9", %"9.preheader"
  br i1 undef, label %"14.loopexit", label %"9"

"14.loopexit":                                    ; preds = %"9"
  br label %"14"

"14":                                             ; preds = %"14.loopexit", %"8"
  br i1 undef, label %"17", label %"15.preheader"

"15.preheader":                                   ; preds = %"14"
  br label %"15"

"15":                                             ; preds = %"15", %"15.preheader"
  br i1 undef, label %"17.loopexit", label %"15"

"17.loopexit":                                    ; preds = %"15"
  br label %"17"

"17":                                             ; preds = %"17.loopexit", %"14"
  br i1 undef, label %"18.preheader", label %"35"

"18.preheader":                                   ; preds = %"17"
  br label %"18"

"18":                                             ; preds = %"33", %"18.preheader"
  br i1 undef, label %"33", label %"19.preheader"

"19.preheader":                                   ; preds = %"18"
  br label %"19"

"19":                                             ; preds = %"31", %"19.preheader"
  br i1 undef, label %"31", label %"20"

"20":                                             ; preds = %"19"
  br i1 undef, label %"21", label %"26"

"21":                                             ; preds = %"20"
  br label %"26"

"26":                                             ; preds = %"21", %"20"
  br i1 undef, label %"30", label %"27"

"27":                                             ; preds = %"26"
  br label %"30"

"30":                                             ; preds = %"27", %"26"
  br label %"31"

"31":                                             ; preds = %"30", %"19"
  br i1 undef, label %"33.loopexit", label %"19"

"33.loopexit":                                    ; preds = %"31"
  br label %"33"

"33":                                             ; preds = %"33.loopexit", %"18"
  br i1 undef, label %"35.loopexit", label %"18"

"35.loopexit":                                    ; preds = %"33"
  br label %"35"

"35":                                             ; preds = %"35.loopexit", %"17"
  br i1 undef, label %"44", label %"36.preheader"

"36.preheader":                                   ; preds = %"35"
  br label %"36"

"36":                                             ; preds = %"39", %"36.preheader"
  br i1 undef, label %"39", label %"37"

"37":                                             ; preds = %"36"
  br label %"39"

"39":                                             ; preds = %"37", %"36"
  br i1 undef, label %"42.preheader", label %"36"

"42.preheader":                                   ; preds = %"39"
  br label %"42"

"42":                                             ; preds = %"42", %"42.preheader"
  br i1 undef, label %"44.loopexit", label %"42"

"44.loopexit":                                    ; preds = %"42"
  br label %"44"

"44":                                             ; preds = %"44.loopexit", %"35"
  br i1 undef, label %"45.preheader", label %"50"

"45.preheader":                                   ; preds = %"44"
  br label %"45"

"45":                                             ; preds = %"48", %"45.preheader"
  br i1 undef, label %"48", label %"46.preheader"

"46.preheader":                                   ; preds = %"45"
  br label %"46"

"46":                                             ; preds = %"46", %"46.preheader"
  br i1 undef, label %"48.loopexit", label %"46"

"48.loopexit":                                    ; preds = %"46"
  br label %"48"

"48":                                             ; preds = %"48.loopexit", %"45"
  br i1 undef, label %"50.loopexit", label %"45"

"50.loopexit":                                    ; preds = %"48"
  br label %"50"

"50":                                             ; preds = %"50.loopexit", %"44"
  br i1 undef, label %"51.preheader", label %"53"

"51.preheader":                                   ; preds = %"50"
  br label %"51"

"51":                                             ; preds = %"51", %"51.preheader"
  br i1 undef, label %"53.loopexit", label %"51"

"53.loopexit":                                    ; preds = %"51"
  br label %"53"

"53":                                             ; preds = %"53.loopexit", %"50"
  br i1 undef, label %return, label %"54"

"54":                                             ; preds = %"53"
  br i1 undef, label %"55.preheader", label %"59"

"55.preheader":                                   ; preds = %"54"
  br label %"55"

"55":                                             ; preds = %"57", %"55.preheader"
  br i1 undef, label %"56", label %"57"

"56":                                             ; preds = %"55"
  br label %"57"

"57":                                             ; preds = %"56", %"55"
  br i1 undef, label %"59.loopexit", label %"55"

"59.loopexit":                                    ; preds = %"57"
  br label %"59"

"59":                                             ; preds = %"59.loopexit", %"54"
  br i1 undef, label %return, label %"60.preheader"

"60.preheader":                                   ; preds = %"59"
  br label %"60"

"60":                                             ; preds = %"64", %"60.preheader"
  br i1 undef, label %"61", label %"64"

"61":                                             ; preds = %"60"
  br i1 undef, label %"62.preheader", label %"64"

"62.preheader":                                   ; preds = %"61"
  br label %"62"

"62":                                             ; preds = %"62", %"62.preheader"
  br i1 undef, label %"64.loopexit", label %"62"

"64.loopexit":                                    ; preds = %"62"
  br label %"64"

"64":                                             ; preds = %"64.loopexit", %"61", %"60"
  br i1 undef, label %return.loopexit, label %"60"

return.loopexit:                                  ; preds = %"64"
  br label %return

return:                                           ; preds = %return.loopexit, %"59", %"53"
  ret void
}

attributes #0 = { nounwind uwtable }
attributes #1 = { argmemonly nounwind }
attributes #2 = { nounwind }
attributes #3 = { nounwind readonly }
attributes #4 = { noreturn }
attributes #5 = { nounwind readnone }
attributes #6 = { nounwind readnone speculatable }
attributes #7 = { alwaysinline nounwind uwtable }

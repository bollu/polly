; RUN: opt %loadPolly -analyze -polly-use-llvm-names -polly-scops -polly-invariant-load-hoisting < %s | FileCheck %s -check-prefix=SCOP
; RUN: opt %loadPolly -S -polly-use-llvm-names -polly-codegen-ppcg -polly-invariant-load-hoisting < %s | FileCheck %s -check-prefix=HOST-IR

; REQUIRES: pollyacc

; SCOP:        Function: __radiation_rg_MOD_coe_so
; SCOP-NEXT    Region: %entry.split---%return
; SCOP-NEXT    Max Loop Depth:  1
; SCOP-NEXT    Invariant Accesses: {
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_entry_split[] -> MemRef_ki1sc[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  :  }
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_entry_split[] -> MemRef_ki1ec[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  :  }
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_3[i0] -> MemRef_kco2[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  : p_1_loaded_from_ki1ec >= p_0_loaded_from_ki1sc }
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_entry_split[] -> MemRef_ki1sd[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  :  }
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_entry_split[] -> MemRef_ki3[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  :  }
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_entry_split[] -> MemRef_ki3sd[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  :  }
; SCOP-NEXT            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT                [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> { Stmt_entry_split[] -> MemRef_ki1ed[0] };
; SCOP-NEXT            Execution Context: [p_0_loaded_from_ki1sc, p_1_loaded_from_ki1ec, p_2_loaded_from_kco2, p_3_loaded_from_ki1sd, p_4] -> {  :  }
; SCOP-NEXT    }



; Check that the kernel launch is generated in tje host IR.
; This declaration would not be generated unless a call to a kernel exists.
; HOST-IR: declare void @polly_launchKernel(i8*, i32, i32, i32, i32, i32, i8*)

; Corresponding fortran code:
;     DO j1 = ki1sc, ki1ec
;       zodgf = 0.0_dp        ! Initialisation
;      IF (kco2 /= 0) THEN     ! Include CO2 contribution
;        zodgf = zodgf + pduco2(j1   ,j3) !* (cobi(kco2,kspec,2)*       &
;      ENDIF                  ! CO2
;       pa4f(j1   )=zodgf !ze*(1.0_dp-(zm**2))*(1.0_dp/(1.0_dp-(zm**2)*(ze**2)))
;   ENDDO

; ModuleID = '__radiation_rg_MOD_coe_so.ll'
source_filename = "llvm-link"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define void @__radiation_rg_MOD_coe_so([0 x double]* noalias %pduh2oc, [0 x double]* noalias %pduh2of, [0 x double]* noalias %pduco2, [0 x double]* noalias %pduo3, [0 x double]* noalias %palogp, [0 x double]* noalias %palogt, [0 x double]* noalias %podsc, [0 x double]* noalias %podsf, [0 x double]* noalias %podac, [0 x double]* noalias %podaf, [0 x double]* noalias %pbsfc, [0 x double]* noalias %pbsff, [0 x double]* noalias %pusfc, [0 x double]* noalias %pusff, [0 x double]* noalias %psmu0, [0 x double]* noalias %pqsmu0, i32* noalias %ki3, i32* noalias %kspec, i32* noalias %kh2o, i32* noalias %kco2, i32* noalias %ko3, i32* noalias %ki1sd, i32* noalias %ki1ed, i32* noalias %ki3sd, i32* noalias %ki3ed, i32* noalias %ki1sc, i32* noalias %ki1ec, i32* noalias %ldebug, i32* noalias %jindex, [0 x double]* noalias %pa1c, [0 x double]* noalias %pa1f, [0 x double]* noalias %pa2c, [0 x double]* noalias %pa2f, [0 x double]* noalias %pa3c, [0 x double]* noalias %pa3f, [0 x double]* noalias %pa4c, [0 x double]* noalias %pa4f, [0 x double]* noalias %pa5c, [0 x double]* noalias %pa5f) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = load i32, i32* %ki1sd, align 4
  %1 = sext i32 %0 to i64
  %2 = load i32, i32* %ki1ed, align 4
  %3 = sext i32 %2 to i64
  %4 = sub nsw i64 1, %1
  %5 = add nsw i64 %4, %3
  %6 = icmp sgt i64 %5, 0
  %7 = select i1 %6, i64 %5, i64 0
  %8 = load i32, i32* %ki3sd, align 4
  %9 = sext i32 %8 to i64
  %10 = load i32, i32* %ki1sd, align 4
  %11 = sext i32 %10 to i64
  %12 = load i32, i32* %ki3, align 4
  %13 = load i32, i32* %ki1sc, align 4
  %14 = load i32, i32* %ki1ec, align 4
  %15 = icmp sgt i32 %13, %14
  br i1 %15, label %return, label %"3.preheader"

"3.preheader":                                    ; preds = %entry.split
  br label %"3"

"3":                                              ; preds = %"3.preheader", %"5"
  %16 = phi i32 [ %31, %"5" ], [ %13, %"3.preheader" ]
  %17 = load i32, i32* %kco2, align 4
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %"5", label %"4"

"4":                                              ; preds = %"3"
  %19 = sext i32 %16 to i64
  %20 = sext i32 %12 to i64
  %tmp = sub nsw i64 %20, %9
  %tmp1 = mul i64 %tmp, %7
  %21 = sub i64 %tmp1, %1
  %22 = add i64 %21, %19
  %23 = getelementptr [0 x double], [0 x double]* %pduco2, i64 0, i64 %22
  %24 = load double, double* %23, align 8
  %25 = fadd double %24, 0.000000e+00
  br label %"5"

"5":                                              ; preds = %"4", %"3"
  %26 = phi double [ %25, %"4" ], [ 0.000000e+00, %"3" ]
  %27 = sext i32 %16 to i64
  %28 = sub nsw i64 %27, %11
  %29 = getelementptr [0 x double], [0 x double]* %pa4f, i64 0, i64 %28
  store double %26, double* %29, align 8
  %30 = icmp eq i32 %16, %14
  %31 = add i32 %16, 1
  br i1 %30, label %return.loopexit, label %"3"

return.loopexit:                                  ; preds = %"5"
  br label %return

return:                                           ; preds = %return.loopexit, %entry.split
  ret void
}

attributes #0 = { nounwind uwtable }

; RUN: opt %loadPolly -analyze -polly-scops < %s | FileCheck %s --check-prefix=SCOP
; RUN: opt %loadPolly -S -polly-codegen-ppcg -polly-acc-dump-kernel-ir < %s | FileCheck %s --check-prefix=KERNEL-IR

; Test that we do recognise and codegen a kernel that has intrinsics.

; Check that we model the kernel as a scop.
; SCOP:      Function: f
; SCOP-NEXT:       Region: %entry.split---%for.end

; Check that the intrinsic call is present in the kernel IR.
; KERNEL-IR:       %sqrt = tail call float @sqrt(float %A.arr.i.val)
; KERNEL-IR-NEXT:  %B.arr.i = getelementptr inbounds float, float* %B, i64 %indvars.iv
; KERNEL-IR-NEXT:  store float %sqrt, float* %B.arr.i, align 4


; void f(float *A, float *B, int N) {
;   for(int i = 0; i < N; i++) {
;       B[i] = sqrt(A[i]);
;   }
; }

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

define void @f(float* %A, float* %B, i32 %N) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %cmp1 = icmp sgt i32 %N, 0
  br i1 %cmp1, label %for.body.lr.ph, label %for.end

for.body.lr.ph:                                   ; preds = %entry.split
  br label %for.body

for.body:                                         ; preds = %for.body.lr.ph, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.body ]
  %A.arr.i = getelementptr inbounds float, float* %A, i64 %indvars.iv
  %A.arr.i.val = load float, float* %A.arr.i, align 4
  ; Call to intrinsic that should be part of the kernel.
  %sqrt = tail call float @sqrt(float %A.arr.i.val)
  %B.arr.i = getelementptr inbounds float, float* %B, i64 %indvars.iv
  store float %sqrt, float* %B.arr.i, align 4

  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %wide.trip.count = zext i32 %N to i64
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body, label %for.cond.for.end_crit_edge

for.cond.for.end_crit_edge:                       ; preds = %for.body
  br label %for.end

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry.split
  ret void
}

; Function Attrs: nounwind readnone
declare float @sqrt(float) #0

attributes #0 = { nounwind readnone }


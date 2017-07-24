; RUN: opt %loadPolly -analyze -polly-scops < %s | FileCheck %s -check-prefix=SCOP
; RUN: opt %loadPolly -S -polly-codegen-ppcg -polly-acc-fail-on-verify-module-failure < %s | FileCheck %s -check-prefix=HOST-IR
; RUN: opt %loadPolly -analyze -polly-codegen-ppcg -polly-acc-fail-on-verify-module-failure -polly-acc-dump-kernel-ir < %s | FileCheck %s -check-prefix=KERNEL-IR

; REQUIRES: pollyacc

; SCOP:      Function: f
; SCOP-NEXT: Region: %for.body---%for.end
; SCOP-NEXT: Max Loop Depth:  1

; Check that kernel launch is generated in host IR.
; the declare would not be generated unless a call to a kernel exists.
; HOST-IR: declare void @polly_launchKernel(i8*, i32, i32, i32, i32, i32, i8*)

; Don't create host memory for MemRef_x_0__phi because we don't need it.
; HOST-IR-NOT:   %p_dev_array_MemRef_x_0__phi = call i8* @polly_allocateMemoryForDevice(i64 4)

; We shouldn't try to recieve MemRef_x_0 as a parameter in the kernel.
; KERNEL-IR-NOT: i8 addrspace(1)* %MemRef_x_0__phi

; void f(int A[], int B[], int control, int C[]) {
;     int x;
; #pragma scop
;     for(int i = 0; i < 1000; i ++) {
;         x = 0;
;         if(control) x = C[i];
;         B[i] = x * A[i];
;
;     }
; #pragma endscop
; }

; ModuleID = 'test.ll'
source_filename = "test.c"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.12.0"

define void @checkPrivatization(i32* %A, i32* %B, i32* %C, i32 %control) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %ifcond

ifcond:                                           ; preds = %entry.split, %xuse
  %indvars.iv1 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next, %xuse ]
  %cmp1 = icmp sgt i32 %control, 4
  br i1 %cmp1, label %xinc, label %xuse

xinc:                                             ; preds = %ifcond
  %arrayidx = getelementptr inbounds i32, i32* %C, i64 %indvars.iv1
  %tmp = load i32, i32* %arrayidx, align 4, !tbaa !2
  br label %xuse

xuse:                                             ; preds = %ifcond, %xinc
  %x.0 = phi i32 [ %tmp, %xinc ], [ 0, %ifcond ]
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv1
  %tmp1 = load i32, i32* %arrayidx3, align 4, !tbaa !2
  %mul = mul nsw i32 %tmp1, %x.0
  %arrayidx5 = getelementptr inbounds i32, i32* %B, i64 %indvars.iv1
  store i32 %mul, i32* %arrayidx5, align 4, !tbaa !2
  %indvars.iv.next = add nuw nsw i64 %indvars.iv1, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 1000
  br i1 %exitcond, label %for.end, label %ifcond

for.end:                                          ; preds = %xuse
  ret void
}

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #0

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #0

attributes #0 = { argmemonly nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"PIC Level", i32 2}
!1 = !{!"clang version 5.0.0 (http://llvm.org/git/clang.git 9a4d019389c762a32274ed1ca1ead93f79acbcd2) (http://llvm.org/git/llvm.git cbe96ddc5f952c02abf6109d313f7cf19e4f054e)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"int", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}

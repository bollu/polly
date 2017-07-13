; RUN: opt %loadPolly -analyze -polly-use-llvm-names -polly-scops \
; RUN: -polly-invariant-load-hoisting < %s | FileCheck %s -check-prefix=SCOP

; RUN: opt %loadPolly -S -polly-use-llvm-names -polly-codegen-ppcg \
; RUN: -polly-invariant-load-hoisting < %s | FileCheck %s -check-prefix=HOST-IR

; This tests that we can correctly code generate invariant loads in
; `BlockGenerators::copyInstruction`.
; In particular, check that this invariant load is handled correctly:
;   %tmp6 = load i32, i32* %control, align 4

; SCOP:       Function: f
; SCOP-NEXT:  Region: %for.body---%for.end
; SCOP-NEXT:  Max Loop Depth:  1
; SCOP-NEXT:  Invariant Accesses: {
; SCOP-NEXT:          ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT:              { Stmt_for_body[i0] -> MemRef_control[0] };
; SCOP-NEXT:          Execution Context: {  :  }
; SCOP-NEXT:  }

; HOST-IR: call void @polly_launchKernel(i8* %19, i32 32, i32 1, i32 32, i32 1, i32 1, i8* %polly_launch_0_params_i8ptr)
; HOST-IR: call void @polly_freeKernel(i8* %19)

; Check that we do not try to copy this instruction in `BlockGenerators`
;     %tmp = load i32, i32* %control
; This load is invariant load hoisted, so it does not make sense to try and
; copy it.


;    void f(int *arr, const int *control) {
;      for (int i = 0; i < 1000; i++) {
;        int t = 0;
;        if (*control > 3) {
;          t += 3;
;        }
;        arr[i] = t;
;      }
;    }
; 

target datalayout = "e-m:o-p:32:32-f64:32:64-f80:128-n8:16:32-S128"
target triple = "i386-apple-macosx10.12.0"

define void @f(i32* %arr, i32* %control) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %for.body

for.body:                                         ; preds = %entry.split, %for.body
  %i.01 = phi i32 [ 0, %entry.split ], [ %inc, %for.body ]
  %tmp = load i32, i32* %control, align 4
  %cmp1 = icmp sgt i32 %tmp, 3
  %. = select i1 %cmp1, i32 3, i32 0
  %arrayidx = getelementptr inbounds i32, i32* %arr, i32 %i.01
  store i32 %., i32* %arrayidx, align 4
  %inc = add nuw nsw i32 %i.01, 1
  %exitcond = icmp eq i32 %inc, 1000
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

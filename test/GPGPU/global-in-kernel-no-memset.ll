; RUN: opt %loadPolly -analyze -polly-scops < %s | FileCheck -check-prefix=SCOPS %s
; RUN: opt %loadPolly  -polly-codegen-ppcg  < %s

; SCOPS:      Function: fn
; SCOPS-NEXT:     Region: %for.inc---%for.exit

target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%struct.ty = type { [40 x [255 x i8]] }

@arr = external global [199 x %struct.ty], align 32

; Function Attrs: argmemonly nounwind
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i32, i1) #0

; Function Attrs: nounwind uwtable
define void @fn() #1 {
entry:
  br label %for.inc

for.inc:                                          ; preds = %for.inc, %entry
  %tmp = phi i64 [ 1, %entry ], [ %tmp3, %for.inc.after ]
  %tmp1 = add nsw i64 %tmp, -1
  br label %for.memset.inc

  ;%tmp2 = getelementptr [199 x %struct.ty], [199 x %struct.ty]* @arr, i64 0, i64 0, i32 0, i64 %tmp1, i64 0
  ;call void @llvm.memset.p0i8.i64(i8* %tmp2, i8 32, i64 255, i32 1, i1 false)

for.memset.inc:

  %memset.idx = phi i64 [0, %for.inc], [%memset.idx.inc, %for.memset.inc]
  %slot = getelementptr [199 x %struct.ty], [199 x %struct.ty]* @arr, i64 0, i64 0, i32 0, i64 %tmp1, i64  %memset.idx
  store i8 32, i8* %slot

  %memset.idx.inc = add nuw nsw i64 %memset.idx, 1
  %memset.exitcond = icmp eq i64 %memset.idx.inc, 254
  br i1 %memset.exitcond, label %for.inc.after, label %for.memset.inc


for.inc.after:
  %tmp3 = add nuw nsw i64 %tmp, 1
  %exitcond = icmp eq i64 %tmp3, 41
  br i1 %exitcond, label %for.exit, label %for.inc

for.exit:                                         ; preds = %for.inc
  ret void
}

attributes #0 = { argmemonly nounwind }
attributes #1 = { nounwind uwtable }

; RUN: opt %loadPolly -polly-detect-full-functions -polly-scop-inliner \
; RUN: -polly-scops -analyze < %s | FileCheck %s

; CHECK:    Max Loop Depth:  2

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.12.0"

define void @to_be_inlined(i32* %A) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %for.body

for.body:                                         ; preds = %entry.split, %for.body
  %indvars.iv1 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv1
  %tmp = load i32, i32* %arrayidx, align 4, !tbaa !3
  %mul = mul nsw i32 %tmp, 10
  store i32 %mul, i32* %arrayidx, align 4, !tbaa !3
  %indvars.iv.next = add nuw nsw i64 %indvars.iv1, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 1000
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

define void @inline_site(i32* %A) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %for.body

for.body:                                         ; preds = %entry.split, %for.body
  %i.01 = phi i32 [ 0, %entry.split ], [ %inc, %for.body ]
  tail call void @to_be_inlined(i32* %A)
  %inc = add nuw nsw i32 %i.01, 1
  %exitcond = icmp eq i32 %inc, 1000
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

attributes #0 = { argmemonly nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{!"clang version 6.0.0 (http://llvm.org/git/clang.git 6660f0d30ef23b3142a6b08f9f41aad3d47c084f) (http://llvm.org/git/llvm.git 052dd78cb30f77a05dc8bb06b851402c4b6c6587)"}
!3 = !{!4, !4, i64 0}
!4 = !{!"int", !5, i64 0}
!5 = !{!"omnipotent char", !6, i64 0}
!6 = !{!"Simple C/C++ TBAA"}

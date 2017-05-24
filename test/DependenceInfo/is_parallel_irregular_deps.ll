; This contains dependences which do not generate the same space
; when called with -poyhedral-info. This tests that we unify these
; correctly, and not crash by calling isl_map_from_union_map directly.


; RUN: opt %loadPolly -polyhedral-info -polly-check-parallel -analyze %s

; static const int N = 200;
; 
; void crash(int A[N]) {
;   int i = 0, j = 0;
;   for (i = 0; i < N; i++) {
;       A[i] = 0;
; 
;     for (j = 0; j < N; j++)
;         A[j] = 42;
;   }
; }
  

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

define void @crash(i32* %A) {
for.body:                                         ; preds = %entry.split, %for.inc
  %indvars.iv3 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next4, %for.inc ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv3
  store i32 0, i32* %arrayidx, align 4
  br label %for.body.inner

for.body.inner:                                        ; preds = %for.body, %for.body.inner
  %indvars.iv = phi i64 [ 0, %for.body ], [ %indvars.iv.next, %for.body.inner ]
  %arrayidx5 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  store i32 42, i32* %arrayidx5, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, 200
  br i1 %exitcond, label %for.body.inner, label %for.inc

for.inc:                                         ; preds = %for.body.inner
  %indvars.iv.next4 = add nuw nsw i64 %indvars.iv3, 1
  %exitcond5 = icmp ne i64 %indvars.iv.next4, 200
  br i1 %exitcond5, label %for.body, label %for.end

for.end:                                         ; preds = %for.inc
  ret void
}

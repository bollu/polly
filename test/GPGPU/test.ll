; RUN: opt %loadPolly -polly-codegen-ppcg -polly-acc-fail-on-verify-module-failure \
; RUN: -disable-output < %s

; ModuleID = 'reduced.ll'
source_filename = "bugpoint-output-cb5513b.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

declare void @fn_to_fence(i32 *%val)


; void f(int *arr, bool shouldcont) {
;     for(int i = 0; ; i++) {
;         for(int j = 0; j < 10; j++) {
;             arr[j] = i;
;         }
;         fence(arr);
;         if (!shouldcont) break;
;     }
; }


; Function Attrs: nounwind uwtable
define void @f(i32 *%arr, i1 %shouldcont) #1 {
entry:
  br label %for.init

for.init:                                             ; preds = %for.end, %entry.split
  %indvar = phi i32 [ %indvar.next, %for.end ], [ 0, %entry ]
  br label %for2.body

for2.body:                                             ; preds = %"65", %"64"
  %indvar2 = phi i32 [ %indvar2.next, %for2.body ], [ 0, %for.init ]
  %indvar2.sext = sext i32 %indvar2 to i64
  %arr.slot = getelementptr i32, i32* %arr, i64 %indvar2.sext
  store i32 %indvar, i32* %arr.slot, align 4
  %exitcond = icmp eq i32 %indvar2, 10
  %indvar2.next = add i32 %indvar2, 1
  br i1 %exitcond, label %for2.body.fence, label %for2.body

for2.body.fence:                                             ; preds = %"65"
  call void @fn_to_fence(i32* %arr) #2
  br i1 %shouldcont, label %for.end, label %exit
for.end:                                             ; preds = %"69"
  %indvar.next = add i32 %indvar, 1
  br label %for.init

exit:                                             ; preds = %"69"
  ret void

}

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) #2

declare void @used_fn(...)


attributes #0 = { argmemonly nounwind }
attributes #1 = { nounwind uwtable }
attributes #2 = { nounwind }

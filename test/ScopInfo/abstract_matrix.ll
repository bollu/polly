; RUN: opt %loadPolly -polly-scops -analyze < %s | FileCheck %s
;
;    float *__polly_get_abstract_matrix_ptr_2d_float(void *A, long i0, long i1)
;        __attribute__((const));
;
;    void foo(void *A) {
;      for (long i = 0; i < 1024; i++)
;        for (long j = 0; j < 1024; j++) {
;          float *Ptr = __polly_get_abstract_matrix_ptr_2d_float(A, i, j);
;          *Ptr += i + j;
;        }
;    }

; Verify that we can model function calls that model abstract memory accesses
; to matrices.

; CHECK:     Arrays {
; CHECK-NEXT:         float MemRef_A[9223372036854775807][9223372036854775807]; // Element size 4
; CHECK-NEXT:     }
; CHECK-NEXT:     Arrays (Bounds as pw_affs) {
; CHECK-NEXT:         float MemRef_A[ { [] -> [(9223372036854775807)] } ][ { [] -> [(9223372036854775807)] } ]; // Element size 4
; CHECK-NEXT:     }
; CHECK-NEXT:     Alias Groups (0):
; CHECK-NEXT:         n/a
; CHECK-NEXT: Statements {
; CHECK-NEXT: 	Stmt_for_body3
; CHECK-NEXT:         Domain :=
; CHECK-NEXT:             { Stmt_for_body3[i0, i1] : 0 <= i0 <= 1023 and 0 <= i1 <= 1023 };
; CHECK-NEXT:         Schedule :=
; CHECK-NEXT:             { Stmt_for_body3[i0, i1] -> [i0, i1] };
; CHECK-NEXT:         ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:             { Stmt_for_body3[i0, i1] -> MemRef_A[i0, i1] };
; CHECK-NEXT:         MustWriteAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:             { Stmt_for_body3[i0, i1] -> MemRef_A[i0, i1] };
; CHECK-NEXT: }

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define void @foo(i8* %A) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc5, %entry
  %i.0 = phi i64 [ 0, %entry ], [ %inc6, %for.inc5 ]
  %exitcond1 = icmp ne i64 %i.0, 1024
  br i1 %exitcond1, label %for.body, label %for.end7

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i64 [ 0, %for.body ], [ %inc, %for.inc ]
  %exitcond = icmp ne i64 %j.0, 1024
  br i1 %exitcond, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %call = call float* @__polly_get_abstract_matrix_ptr_2d_float(i8* %A, i64 %i.0, i64 %j.0) #2
  %add = add nuw nsw i64 %i.0, %j.0
  %conv = sitofp i64 %add to float
  %tmp = load float, float* %call, align 4
  %add4 = fadd float %tmp, %conv
  store float %add4, float* %call, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body3
  %inc = add nuw nsw i64 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond1
  br label %for.inc5

for.inc5:                                         ; preds = %for.end
  %inc6 = add nuw nsw i64 %i.0, 1
  br label %for.cond

for.end7:                                         ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind readnone
declare float* @__polly_get_abstract_matrix_ptr_2d_float(i8*, i64, i64) #1

attributes #0 = { noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

; RUN: opt %loadPolly -polly-scops -analyze \
; RUN: -polly-invariant-load-hoisting < %s | FileCheck %s -check-prefix=SCOP
;
; RUN: opt %loadPolly -polly-scops -analyze  -polly-invariant-load-hoisting \
; RUN: -polly-codegen-ppcg -polly-acc-dump-kernel-ir < %s | FileCheck %s -check-prefix=KERNEL-IR
;
; REQUIRES: pollyacc
;
; SCOP:         Function: f
; SCOP-NEXT:    Region: %for.body---%for.end10
; SCOP-NEXT:    Max Loop Depth:  1
; SCOP-NEXT:    Invariant Accesses: {
; SCOP-NEXT:            ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT:                { Stmt_for_body[i0] -> MemRef_A_addr[0] };
; SCOP-NEXT:            Execution Context: {  :  }
; SCOP-NEXT:    }
; SCOP:         Arrays {
; SCOP-NEXT:        i32* MemRef_A_addr[*]; // Element size 8
; SCOP-NEXT:        i32 MemRef_tmp[*]; [BasePtrOrigin: MemRef_A_addr] // Element size 4
; SCOP-NEXT:        i32 MemRef_B[*]; // Element size 4
; SCOP-NEXT:    }

; Check that we model the access of A and B but *not* the access of &A in
; Stmt_for_body5

; SCOP:         Statements {
; SCOP-NEXT:    	Stmt_for_body
; SCOP-NEXT:            Domain :=
; SCOP-NEXT:                { Stmt_for_body[i0] : 0 <= i0 <= 999 };
; SCOP-NEXT:            Schedule :=
; SCOP-NEXT:                { Stmt_for_body[i0] -> [0, i0] };
; SCOP-NEXT:            MustWriteAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT:                { Stmt_for_body[i0] -> MemRef_tmp[i0] };
; SCOP-NEXT:    	Stmt_for_body5
; SCOP-NEXT:            Domain :=
; SCOP-NEXT:                { Stmt_for_body5[i0] : 0 <= i0 <= 19999 };
; SCOP-NEXT:            Schedule :=
; SCOP-NEXT:                { Stmt_for_body5[i0] -> [1, i0] };
; SCOP-NEXT:            MustWriteAccess :=	[Reduction Type: NONE] [Scalar: 0]
; SCOP-NEXT:                { Stmt_for_body5[i0] -> MemRef_B[i0] };
; SCOP-NEXT:    }


; KERNEL-IR:      polly.stmt.for.body5:                             ; preds = %entry
; KERNEL-IR-NEXT:   %p_tmp4 = ptrtoint i32** %A.addr to i64
; KERNEL-IR-NEXT:   %p_tmp5 = trunc i64 %p_tmp4 to i32
; KERNEL-IR-NEXT:   %polly.access.cast.MemRef_B = bitcast i8 addrspace(1)* %MemRef_B to i32 addrspace(1)*
; KERNEL-IR-NEXT:   %4 = mul nsw i64 32, %b0
; KERNEL-IR-NEXT:   %5 = add nsw i64 %4, %t0
; KERNEL-IR-NEXT:   %polly.access.MemRef_B = getelementptr i32, i32 addrspace(1)* %polly.access.cast.MemRef_B, i64 %5
; KERNEL-IR-NEXT:   store i32 %p_tmp5, i32 addrspace(1)* %polly.access.MemRef_B, align 4


; Check that we launch a kernel
; HOST-IR:      call void @polly_launchKernel
; HOST-IR-NEXT: call void @polly_freeKernel

; void f(int *A, int *B) {
;     Kernel #0
;     for(int i = 0; i < 1000; i++) {
;         A[i] = 100;
;     }
; 
;     Kernel #1
;     for(int i = 0; i < 20000; i++) {
;         B[i] = &A;
;     }
; }

; Check that we still send A to kernel #1 even though we don't load/store
; from it.
; This is a regression test.

; Polly constructs a set of values called 'SubtreeValues' for each kernel.
; This refers to the set of values that are potentially used by a kernel,
; and are hence sent over to the kernel.
; This would also include the base pointers of all arrays.
; However, we send arrays separately. So, we remove array base pointers
; from SubtreeValues to prevent double-sending.
; However, we remove *all* arrays from the *Scop* from SubtreeValues.
; We _should_ remove *all modeled (loaded/stored)* arrays in the *Kernel* from SubtreeValues.
; Make sure that in this case, we _do_ actually keep `A` in SubtreeValues,
; because we do not model a load or a store to A, but we _do_ use A in Kernel#1
; in the form of a ptrtoint.



target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.12.0"

define void @f(i32* %A, i32* %B) {
entry:
  %A.addr = alloca i32*, align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  store i32* %A, i32** %A.addr, align 8, !tbaa !3
  br label %for.body

for.body:                                         ; preds = %entry.split, %for.body
  %indvars.iv13 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next2, %for.body ]
  %tmp = load i32*, i32** %A.addr, align 8, !tbaa !3
  %arrayidx = getelementptr inbounds i32, i32* %tmp, i64 %indvars.iv13
  store i32 100, i32* %arrayidx, align 4, !tbaa !7
  %indvars.iv.next2 = add nuw nsw i64 %indvars.iv13, 1
  %exitcond3 = icmp eq i64 %indvars.iv.next2, 1000
  br i1 %exitcond3, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  br label %for.body5

for.body5:                                        ; preds = %for.end, %for.body5
  %indvars.iv2 = phi i64 [ 0, %for.end ], [ %indvars.iv.next, %for.body5 ]
  %tmp4 = ptrtoint i32** %A.addr to i64
  %tmp5 = trunc i64 %tmp4 to i32
  %arrayidx7 = getelementptr inbounds i32, i32* %B, i64 %indvars.iv2
  store i32 %tmp5, i32* %arrayidx7, align 4, !tbaa !7
  %indvars.iv.next = add nuw nsw i64 %indvars.iv2, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 20000
  br i1 %exitcond, label %for.end10, label %for.body5

for.end10:                                        ; preds = %for.body5
  ret void
}

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #0

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #0

attributes #0 = { argmemonly nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{!"clang version 6.0.0 (http://llvm.org/git/clang.git 3d47fbe0d75b2d1bb5353cc73a9484502860b571) (http://llvm.org/git/llvm.git dbf8de9323906a469b4680f06a8f3e9842dc20f4)"}
!3 = !{!4, !4, i64 0}
!4 = !{!"any pointer", !5, i64 0}
!5 = !{!"omnipotent char", !6, i64 0}
!6 = !{!"Simple C/C++ TBAA"}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !5, i64 0}

; RUN: opt %loadPolly -analyze -polly-scops < %s | FileCheck -check-prefix=SCOPS %s
; RUN: opt %loadPolly  -polly-codegen-ppcg  < %s

; SCOPS:      Function: __m_serializer_old_MOD_writejsondatafieldinfo
; SCOPS-NEXT:     Region: %"388"---%"389"


target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

module asm "\09.ident\09\22GCC: (GNU) 4.6.4 LLVM: 3.3.1\22"

%struct.t_datafieldinfo.10.64.91.118.307.361.442.685.766.793.847.874.1063.1090.1117.1144.1171.1198.1225.1566 = type { i32, [50 x i8], i32, [32 x i8], i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, [40 x [50 x i8]], [40 x [255 x i8]] }

@__m_serializer_old_MOD_gdatafieldinfo = external global [199 x %struct.t_datafieldinfo.10.64.91.118.307.361.442.685.766.793.847.874.1063.1090.1117.1144.1171.1198.1225.1566], align 32

; Function Attrs: argmemonly nounwind
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i32, i1) #0

; Function Attrs: nounwind uwtable
define void @__m_serializer_old_MOD_writejsondatafieldinfo() #1 {
entry:
  br label %"388"

"388":                                            ; preds = %"388", %entry
  %0 = phi i64 [ 1, %entry ], [ %3, %"388" ]
  %1 = add nsw i64 %0, -1
  %2 = getelementptr [199 x %struct.t_datafieldinfo.10.64.91.118.307.361.442.685.766.793.847.874.1063.1090.1117.1144.1171.1198.1225.1566], [199 x %struct.t_datafieldinfo.10.64.91.118.307.361.442.685.766.793.847.874.1063.1090.1117.1144.1171.1198.1225.1566]* @__m_serializer_old_MOD_gdatafieldinfo, i64 0, i64 0, i32 21, i64 %1, i64 0
  call void @llvm.memset.p0i8.i64(i8* %2, i8 32, i64 255, i32 1, i1 false)
  %3 = add nuw nsw i64 %0, 1
  %exitcond = icmp eq i64 %3, 41
  br i1 %exitcond, label %"389", label %"388"

"389":                                            ; preds = %"388"
  ret void
}

attributes #0 = { argmemonly nounwind }
attributes #1 = { nounwind uwtable }

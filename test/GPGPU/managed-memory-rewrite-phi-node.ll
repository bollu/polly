; RUN: opt %loadPolly -S \
; RUN: -polly-acc-rewrite-managed-memory \
; RUN: -polly-acc-rewrite-ignore-linkage-for-globals < %s 

source_filename = "bugpoint-output-1e7fd97.bc"
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

%"struct.array3_real(kind=8).3.29.107.289.315.341.419.471.549.627.653.679.809.835.1017.1043.1069.1145" = type { i8*, i64, i64, [3 x %struct.descriptor_dimension.0.26.104.286.312.338.416.468.546.624.650.676.806.832.1014.1040.1066.1144] }
%struct.descriptor_dimension.0.26.104.286.312.338.416.468.546.624.650.676.806.832.1014.1040.1066.1144 = type { i64, i64, i64 }
%"struct.array4_real(kind=8).4.30.108.290.316.342.420.472.550.628.654.680.810.836.1018.1044.1070.1146" = type { i8*, i64, i64, [4 x %struct.descriptor_dimension.0.26.104.286.312.338.416.468.546.624.650.676.806.832.1014.1040.1066.1144] }

@__data_fields_MOD_w_g1 = external global %"struct.array3_real(kind=8).3.29.107.289.315.341.419.471.549.627.653.679.809.835.1017.1043.1069.1145", align 32
@__data_fields_MOD_t_snow_mult = global %"struct.array4_real(kind=8).4.30.108.290.316.342.420.472.550.628.654.680.810.836.1018.1044.1070.1146" zeroinitializer, align 32

; Function Attrs: nounwind uwtable
define void @__src_allocation_MOD_deallocate_fields() #0 {
entry:
  br i1 undef, label %"252", label %"247"

"247":                                            ; preds = %entry
  br label %"256.sink.split"

"252":                                            ; preds = %entry
  br label %"256.sink.split"

"256.sink.split":                                 ; preds = %"252", %"247"
  %.sink = phi i8** [ getelementptr inbounds (%"struct.array3_real(kind=8).3.29.107.289.315.341.419.471.549.627.653.679.809.835.1017.1043.1069.1145", %"struct.array3_real(kind=8).3.29.107.289.315.341.419.471.549.627.653.679.809.835.1017.1043.1069.1145"* @__data_fields_MOD_w_g1, i64 0, i32 0), %"252" ], [ getelementptr inbounds (%"struct.array4_real(kind=8).4.30.108.290.316.342.420.472.550.628.654.680.810.836.1018.1044.1070.1146", %"struct.array4_real(kind=8).4.30.108.290.316.342.420.472.550.628.654.680.810.836.1018.1044.1070.1146"* @__data_fields_MOD_t_snow_mult, i64 0, i32 0), %"247" ]
  ret void
}

attributes #0 = { nounwind uwtable }

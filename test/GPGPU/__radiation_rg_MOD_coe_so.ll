; RUN: opt %loadPolly -S -polly-codegen-ppcg \
; RUN: -polly-invariant-load-hoisting -polly-acc-fail-on-verify-module-failure \
; RUN: -polly-acc-use-shared -polly-acc-use-private \
; RUN: -polly-use-llvm-names < %s | FileCheck %s

; CHECK: polly_allocateMemoryForDevice(i64 0)xx
; CHECK-NOT: polly_allocateMemoryForDevice(i64 0)

target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-unknown-linux-gnu"

%struct.__st_parameter_dt = type { %struct.__st_parameter_common, i64, i64*, i64*, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, [256 x i8], i32*, i64, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, i32, i8*, i8*, i32, [4 x i8] }
%struct.__st_parameter_common = type { i32, i32, i8*, i32, i32, i8*, i32* }

@__data_radiation_MOD_cobti = external global [168 x double], align 32
@__data_radiation_MOD_cobi = external global [168 x double], align 32
@__data_radiation_MOD_coali = external global [168 x double], align 32
@.cst.559 = external hidden constant [58 x i8], align 64
@.cst103.653 = external hidden constant [42 x i8], align 64
@.cst104.654 = external hidden constant [25 x i8], align 8
@0 = external hidden constant i32
@1 = external hidden constant i32
@.cst105.655 = external hidden constant [10 x i8], align 8
@.cst106.656 = external hidden constant [18 x i8], align 8
@.cst107.657 = external hidden constant [18 x i8], align 8
@.cst108.658 = external hidden constant [18 x i8], align 8
@.cst109.659 = external hidden constant [18 x i8], align 8
@.cst110.660 = external hidden constant [18 x i8], align 8
@.cst111.661 = external hidden constant [25 x i8], align 8
@.cst112.662 = external hidden constant [25 x i8], align 8
@.cst113.663 = external hidden constant [25 x i8], align 8
@.cst114.664 = external hidden constant [25 x i8], align 8
@.cst115.665 = external hidden constant [25 x i8], align 8
@.cst116.666 = external hidden constant [35 x i8], align 64
@.cst117.667 = external hidden constant [35 x i8], align 64
@.cst118.668 = external hidden constant [35 x i8], align 64
@.cst119.669 = external hidden constant [35 x i8], align 64
@.cst120.670 = external hidden constant [35 x i8], align 64

declare void @_gfortran_st_write(%struct.__st_parameter_dt*)

declare void @_gfortran_transfer_character_write(%struct.__st_parameter_dt*, i8*, i32)

declare void @_gfortran_st_write_done(%struct.__st_parameter_dt*)

declare void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt*, i8*, i32)

declare void @_gfortran_transfer_real_write(%struct.__st_parameter_dt*, i8*, i32)

; Function Attrs: nounwind readnone
declare double @llvm.cos.f64(double) #0

; Function Attrs: nounwind readnone
declare double @llvm.copysign.f64(double, double) #0

; Function Attrs: nounwind readnone
declare double @llvm.sqrt.f64(double) #0

; Function Attrs: nounwind uwtable
define void @__radiation_rg_MOD_coe_so([0 x double]* noalias %pduh2oc, [0 x double]* noalias %pduh2of, [0 x double]* noalias %pduco2, [0 x double]* noalias %pduo3, [0 x double]* noalias %palogp, [0 x double]* noalias %palogt, [0 x double]* noalias %podsc, [0 x double]* noalias %podsf, [0 x double]* noalias %podac, [0 x double]* noalias %podaf, [0 x double]* noalias %pbsfc, [0 x double]* noalias %pbsff, [0 x double]* noalias %pusfc, [0 x double]* noalias %pusff, [0 x double]* noalias %psmu0, [0 x double]* noalias %pqsmu0, i32* noalias %ki3, i32* noalias %kspec, i32* noalias %kh2o, i32* noalias %kco2, i32* noalias %ko3, i32* noalias %ki1sd, i32* noalias %ki1ed, i32* noalias %ki3sd, i32* noalias %ki3ed, i32* noalias %ki1sc, i32* noalias %ki1ec, i32* noalias %ldebug, i32* noalias %jindex, [0 x double]* noalias %pa1c, [0 x double]* noalias %pa1f, [0 x double]* noalias %pa2c, [0 x double]* noalias %pa2f, [0 x double]* noalias %pa3c, [0 x double]* noalias %pa3f, [0 x double]* noalias %pa4c, [0 x double]* noalias %pa4f, [0 x double]* noalias %pa5c, [0 x double]* noalias %pa5f) #1 {
entry:
  %j3 = alloca i32, align 4
  %dt_parm.1573 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1574 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1575 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1576 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1577 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1578 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1579 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1580 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1581 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1582 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1583 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1584 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1589 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1590 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1591 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1592 = alloca %struct.__st_parameter_dt, align 8
  %dt_parm.1593 = alloca %struct.__st_parameter_dt, align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = load i32, i32* %ki1sd, align 4
  %1 = sext i32 %0 to i64
  %2 = load i32, i32* %ki1ed, align 4
  %3 = sext i32 %2 to i64
  %4 = sub nsw i64 1, %1
  %5 = add nsw i64 %4, %3
  %6 = icmp sgt i64 %5, 0
  %7 = select i1 %6, i64 %5, i64 0
  %8 = load i32, i32* %ki3sd, align 4
  %9 = sext i32 %8 to i64
  %10 = mul i64 %7, %9
  %sum = add i64 %10, %1
  %11 = load i32, i32* %ki1sd, align 4
  %12 = sext i32 %11 to i64
  %13 = load i32, i32* %ki1ed, align 4
  %14 = sext i32 %13 to i64
  %15 = sub nsw i64 1, %12
  %16 = add nsw i64 %15, %14
  %17 = icmp sgt i64 %16, 0
  %18 = select i1 %17, i64 %16, i64 0
  %19 = load i32, i32* %ki3sd, align 4
  %20 = sext i32 %19 to i64
  %21 = mul i64 %18, %20
  %sum28 = add i64 %21, %12
  %22 = load i32, i32* %ki1sd, align 4
  %23 = sext i32 %22 to i64
  %24 = load i32, i32* %ki1ed, align 4
  %25 = sext i32 %24 to i64
  %26 = sub nsw i64 1, %23
  %27 = add nsw i64 %26, %25
  %28 = icmp sgt i64 %27, 0
  %29 = select i1 %28, i64 %27, i64 0
  %30 = load i32, i32* %ki3sd, align 4
  %31 = sext i32 %30 to i64
  %32 = mul i64 %29, %31
  %sum29 = add i64 %32, %23
  %33 = load i32, i32* %ki1sd, align 4
  %34 = sext i32 %33 to i64
  %35 = load i32, i32* %ki1ed, align 4
  %36 = sext i32 %35 to i64
  %37 = sub nsw i64 1, %34
  %38 = add nsw i64 %37, %36
  %39 = icmp sgt i64 %38, 0
  %40 = select i1 %39, i64 %38, i64 0
  %41 = load i32, i32* %ki3sd, align 4
  %42 = sext i32 %41 to i64
  %43 = mul i64 %40, %42
  %sum30 = add i64 %43, %34
  %44 = load i32, i32* %ki1sd, align 4
  %45 = sext i32 %44 to i64
  %46 = sext i32 %44 to i64
  %47 = load i32, i32* %ki1ed, align 4
  %48 = sext i32 %47 to i64
  %49 = sub nsw i64 1, %46
  %50 = add nsw i64 %49, %48
  %51 = icmp sgt i64 %50, 0
  %52 = select i1 %51, i64 %50, i64 0
  %53 = load i32, i32* %ki3sd, align 4
  %54 = sext i32 %53 to i64
  %55 = mul i64 %52, %54
  %sum31 = add i64 %55, %46
  %56 = load i32, i32* %ki1sd, align 4
  %57 = sext i32 %56 to i64
  %58 = load i32, i32* %ki1ed, align 4
  %59 = sext i32 %58 to i64
  %60 = sub nsw i64 1, %57
  %61 = add nsw i64 %60, %59
  %62 = icmp sgt i64 %61, 0
  %63 = select i1 %62, i64 %61, i64 0
  %64 = load i32, i32* %ki3sd, align 4
  %65 = sext i32 %64 to i64
  %66 = mul i64 %63, %65
  %sum32 = add i64 %66, %57
  %67 = load i32, i32* %ki1sd, align 4
  %68 = sext i32 %67 to i64
  %69 = load i32, i32* %ki1ed, align 4
  %70 = sext i32 %69 to i64
  %71 = sub nsw i64 1, %68
  %72 = add nsw i64 %71, %70
  %73 = icmp sgt i64 %72, 0
  %74 = select i1 %73, i64 %72, i64 0
  %75 = load i32, i32* %ki3sd, align 4
  %76 = sext i32 %75 to i64
  %77 = load i32, i32* %ki1sd, align 4
  %78 = sext i32 %77 to i64
  %79 = load i32, i32* %ki1ed, align 4
  %80 = sext i32 %79 to i64
  %81 = sub nsw i64 1, %78
  %82 = add nsw i64 %81, %80
  %83 = icmp sgt i64 %82, 0
  %84 = select i1 %83, i64 %82, i64 0
  %85 = load i32, i32* %ki3sd, align 4
  %86 = sext i32 %85 to i64
  %87 = mul i64 %84, %86
  %sum33 = add i64 %87, %78
  %88 = load i32, i32* %ki1sd, align 4
  %89 = sext i32 %88 to i64
  %90 = load i32, i32* %ki1ed, align 4
  %91 = sext i32 %90 to i64
  %92 = sub nsw i64 1, %89
  %93 = add nsw i64 %92, %91
  %94 = icmp sgt i64 %93, 0
  %95 = select i1 %94, i64 %93, i64 0
  %96 = load i32, i32* %ki3sd, align 4
  %97 = sext i32 %96 to i64
  %98 = mul i64 %95, %97
  %sum34 = add i64 %98, %89
  %99 = load i32, i32* %ki1sd, align 4
  %100 = sext i32 %99 to i64
  %101 = load i32, i32* %ki1ed, align 4
  %102 = sext i32 %101 to i64
  %103 = sub nsw i64 1, %100
  %104 = add nsw i64 %103, %102
  %105 = icmp sgt i64 %104, 0
  %106 = select i1 %105, i64 %104, i64 0
  %107 = load i32, i32* %ki3sd, align 4
  %108 = sext i32 %107 to i64
  %109 = load i32, i32* %ki1sd, align 4
  %110 = sext i32 %109 to i64
  %111 = sext i32 %109 to i64
  %112 = sext i32 %109 to i64
  %113 = sext i32 %109 to i64
  %114 = sext i32 %109 to i64
  %115 = sext i32 %109 to i64
  %116 = load i32, i32* %ki1sd, align 4
  %117 = sext i32 %116 to i64
  %118 = load i32, i32* %ki1ed, align 4
  %119 = sext i32 %118 to i64
  %120 = sub nsw i64 1, %117
  %121 = add nsw i64 %120, %119
  %122 = icmp sgt i64 %121, 0
  %123 = select i1 %122, i64 %121, i64 0
  %124 = load i32, i32* %ki3sd, align 4
  %125 = sext i32 %124 to i64
  %126 = load i32, i32* %ki1sd, align 4
  %127 = sext i32 %126 to i64
  %128 = load i32, i32* %ki1ed, align 4
  %129 = sext i32 %128 to i64
  %130 = sub nsw i64 1, %127
  %131 = add nsw i64 %130, %129
  %132 = icmp sgt i64 %131, 0
  %133 = select i1 %132, i64 %131, i64 0
  %134 = load i32, i32* %ki3sd, align 4
  %135 = sext i32 %134 to i64
  %136 = mul i64 %133, %135
  %sum35 = add i64 %136, %127
  %137 = load i32, i32* %ki1sd, align 4
  %138 = sext i32 %137 to i64
  %139 = load i32, i32* %ki1ed, align 4
  %140 = sext i32 %139 to i64
  %141 = sub nsw i64 1, %138
  %142 = add nsw i64 %141, %140
  %143 = icmp sgt i64 %142, 0
  %144 = select i1 %143, i64 %142, i64 0
  %145 = load i32, i32* %ki3sd, align 4
  %146 = sext i32 %145 to i64
  %147 = mul i64 %144, %146
  %sum36 = add i64 %147, %138
  %148 = load i32, i32* %ki1sd, align 4
  %149 = sext i32 %148 to i64
  %150 = load i32, i32* %ki1ed, align 4
  %151 = sext i32 %150 to i64
  %152 = sub nsw i64 1, %149
  %153 = add nsw i64 %152, %151
  %154 = icmp sgt i64 %153, 0
  %155 = select i1 %154, i64 %153, i64 0
  %156 = load i32, i32* %ki3sd, align 4
  %157 = sext i32 %156 to i64
  %158 = load i32, i32* %ki1sd, align 4
  %159 = sext i32 %158 to i64
  %160 = sext i32 %158 to i64
  %161 = sext i32 %158 to i64
  %162 = sext i32 %158 to i64
  %163 = sext i32 %158 to i64
  %164 = load i32, i32* %ki3, align 4
  store i32 %164, i32* %j3, align 4
  %165 = load i32, i32* %ldebug, align 4, !range !0
  %166 = icmp eq i32 %165, 0
  br i1 %166, label %"5", label %"3"

"3":                                              ; preds = %entry.split
  %167 = load i32, i32* %jindex, align 4
  %168 = icmp eq i32 %167, 4
  br i1 %168, label %"4", label %"5"

"4":                                              ; preds = %"3"
  %169 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1573, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %169, align 8
  %170 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1573, i64 0, i32 0, i32 3
  store i32 3210, i32* %170, align 8
  %171 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1573, i64 0, i32 0, i32 0
  store i32 128, i32* %171, align 8
  %172 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1573, i64 0, i32 0, i32 1
  store i32 6, i32* %172, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1573) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1573, i8* getelementptr inbounds ([42 x i8], [42 x i8]* @.cst103.653, i64 0, i64 0), i32 42) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1573) #3
  %173 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1574, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %173, align 8
  %174 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1574, i64 0, i32 0, i32 3
  store i32 3211, i32* %174, align 8
  %175 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1574, i64 0, i32 0, i32 0
  store i32 128, i32* %175, align 8
  %176 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1574, i64 0, i32 0, i32 1
  store i32 6, i32* %176, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1574) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1574, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst104.654, i64 0, i64 0), i32 25) #3
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1574, i8* nonnull bitcast (i32* @0 to i8*), i32 4) #3
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1574, i8* nonnull bitcast (i32* @1 to i8*), i32 4) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1574, i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.cst105.655, i64 0, i64 0), i32 10) #3
  %177 = bitcast i32* %j3 to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1574, i8* nonnull %177, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1574) #3
  %178 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1575, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %178, align 8
  %179 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1575, i64 0, i32 0, i32 3
  store i32 3212, i32* %179, align 8
  %180 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1575, i64 0, i32 0, i32 0
  store i32 128, i32* %180, align 8
  %181 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1575, i64 0, i32 0, i32 1
  store i32 6, i32* %181, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1575) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1575, i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.cst106.656, i64 0, i64 0), i32 18) #3
  %182 = bitcast i32* %kspec to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1575, i8* noalias %182, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1575) #3
  %183 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1576, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %183, align 8
  %184 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1576, i64 0, i32 0, i32 3
  store i32 3213, i32* %184, align 8
  %185 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1576, i64 0, i32 0, i32 0
  store i32 128, i32* %185, align 8
  %186 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1576, i64 0, i32 0, i32 1
  store i32 6, i32* %186, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1576) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1576, i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.cst107.657, i64 0, i64 0), i32 18) #3
  %187 = bitcast i32* %j3 to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1576, i8* nonnull %187, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1576) #3
  %188 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1577, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %188, align 8
  %189 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1577, i64 0, i32 0, i32 3
  store i32 3214, i32* %189, align 8
  %190 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1577, i64 0, i32 0, i32 0
  store i32 128, i32* %190, align 8
  %191 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1577, i64 0, i32 0, i32 1
  store i32 6, i32* %191, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1577) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1577, i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.cst108.658, i64 0, i64 0), i32 18) #3
  %192 = bitcast i32* %kh2o to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1577, i8* noalias %192, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1577) #3
  %193 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1578, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %193, align 8
  %194 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1578, i64 0, i32 0, i32 3
  store i32 3215, i32* %194, align 8
  %195 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1578, i64 0, i32 0, i32 0
  store i32 128, i32* %195, align 8
  %196 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1578, i64 0, i32 0, i32 1
  store i32 6, i32* %196, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1578) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1578, i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.cst109.659, i64 0, i64 0), i32 18) #3
  %197 = bitcast i32* %kco2 to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1578, i8* noalias %197, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1578) #3
  %198 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1579, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %198, align 8
  %199 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1579, i64 0, i32 0, i32 3
  store i32 3216, i32* %199, align 8
  %200 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1579, i64 0, i32 0, i32 0
  store i32 128, i32* %200, align 8
  %201 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1579, i64 0, i32 0, i32 1
  store i32 6, i32* %201, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1579) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1579, i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.cst110.660, i64 0, i64 0), i32 18) #3
  %202 = bitcast i32* %ko3 to i8*
  call void @_gfortran_transfer_integer_write(%struct.__st_parameter_dt* nonnull %dt_parm.1579, i8* noalias %202, i32 4) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1579) #3
  %203 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1580, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %203, align 8
  %204 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1580, i64 0, i32 0, i32 3
  store i32 3217, i32* %204, align 8
  %205 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1580, i64 0, i32 0, i32 0
  store i32 128, i32* %205, align 8
  %206 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1580, i64 0, i32 0, i32 1
  store i32 6, i32* %206, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1580) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1580, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst111.661, i64 0, i64 0), i32 25) #3
  %207 = load i32, i32* %j3, align 4
  %208 = sext i32 %207 to i64
  %209 = mul i64 %7, %208
  %210 = sub i64 50, %sum
  %211 = add i64 %210, %209
  %212 = getelementptr [0 x double], [0 x double]* %pduh2of, i64 0, i64 %211
  %213 = bitcast double* %212 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1580, i8* %213, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1580) #3
  %214 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1581, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %214, align 8
  %215 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1581, i64 0, i32 0, i32 3
  store i32 3218, i32* %215, align 8
  %216 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1581, i64 0, i32 0, i32 0
  store i32 128, i32* %216, align 8
  %217 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1581, i64 0, i32 0, i32 1
  store i32 6, i32* %217, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1581) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1581, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst112.662, i64 0, i64 0), i32 25) #3
  %218 = load i32, i32* %j3, align 4
  %219 = sext i32 %218 to i64
  %220 = mul i64 %18, %219
  %221 = sub i64 50, %sum28
  %222 = add i64 %221, %220
  %223 = getelementptr [0 x double], [0 x double]* %pduh2oc, i64 0, i64 %222
  %224 = bitcast double* %223 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1581, i8* %224, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1581) #3
  %225 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1582, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %225, align 8
  %226 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1582, i64 0, i32 0, i32 3
  store i32 3219, i32* %226, align 8
  %227 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1582, i64 0, i32 0, i32 0
  store i32 128, i32* %227, align 8
  %228 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1582, i64 0, i32 0, i32 1
  store i32 6, i32* %228, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1582) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1582, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst113.663, i64 0, i64 0), i32 25) #3
  %229 = load i32, i32* %j3, align 4
  %230 = sext i32 %229 to i64
  %231 = mul i64 %29, %230
  %232 = sub i64 50, %sum29
  %233 = add i64 %232, %231
  %234 = getelementptr [0 x double], [0 x double]* %pduco2, i64 0, i64 %233
  %235 = bitcast double* %234 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1582, i8* %235, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1582) #3
  %236 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1583, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %236, align 8
  %237 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1583, i64 0, i32 0, i32 3
  store i32 3220, i32* %237, align 8
  %238 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1583, i64 0, i32 0, i32 0
  store i32 128, i32* %238, align 8
  %239 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1583, i64 0, i32 0, i32 1
  store i32 6, i32* %239, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1583) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1583, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst114.664, i64 0, i64 0), i32 25) #3
  %240 = load i32, i32* %j3, align 4
  %241 = sext i32 %240 to i64
  %242 = mul i64 %40, %241
  %243 = sub i64 50, %sum30
  %244 = add i64 %243, %242
  %245 = getelementptr [0 x double], [0 x double]* %pduo3, i64 0, i64 %244
  %246 = bitcast double* %245 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1583, i8* %246, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1583) #3
  %247 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1584, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %247, align 8
  %248 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1584, i64 0, i32 0, i32 3
  store i32 3221, i32* %248, align 8
  %249 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1584, i64 0, i32 0, i32 0
  store i32 128, i32* %249, align 8
  %250 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1584, i64 0, i32 0, i32 1
  store i32 6, i32* %250, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1584) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1584, i8* getelementptr inbounds ([25 x i8], [25 x i8]* @.cst115.665, i64 0, i64 0), i32 25) #3
  %251 = sub nsw i64 50, %45
  %252 = getelementptr [0 x double], [0 x double]* %psmu0, i64 0, i64 %251
  %253 = bitcast double* %252 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1584, i8* %253, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1584) #3
  br label %"5"

"5":                                              ; preds = %"4", %"3", %entry.split
  %254 = load i32, i32* %ki1sc, align 4
  %255 = load i32, i32* %ki1ec, align 4
  %256 = icmp sgt i32 %254, %255
  br i1 %256, label %"34", label %"6.preheader"

"6.preheader":                                    ; preds = %"5"
  br label %"6"

"6":                                              ; preds = %"32", %"6.preheader"
  %257 = phi i32 [ %894, %"32" ], [ %254, %"6.preheader" ]
  %258 = load i32, i32* %kco2, align 4
  %259 = icmp eq i32 %258, 0
  br i1 %259, label %"8", label %"7"

"7":                                              ; preds = %"6"
  %260 = sext i32 %257 to i64
  %261 = load i32, i32* %j3, align 4
  %262 = sext i32 %261 to i64
  %263 = mul i64 %29, %262
  %264 = sub i64 %260, %sum29
  %265 = add i64 %264, %263
  %266 = getelementptr [0 x double], [0 x double]* %pduco2, i64 0, i64 %265
  %267 = load double, double* %266, align 8
  %268 = load i32, i32* %kco2, align 4
  %269 = sext i32 %268 to i64
  %270 = load i32, i32* %kspec, align 4
  %271 = sext i32 %270 to i64
  %272 = mul nsw i64 %271, 7
  %273 = add nsw i64 %269, 48
  %274 = add i64 %273, %272
  %275 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobi, i64 0, i64 %274
  %276 = load double, double* %275, align 8
  %277 = load i32, i32* %kco2, align 4
  %278 = sext i32 %277 to i64
  %279 = load i32, i32* %kspec, align 4
  %280 = sext i32 %279 to i64
  %281 = mul nsw i64 %280, 7
  %282 = add nsw i64 %278, 48
  %283 = add i64 %282, %281
  %284 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_coali, i64 0, i64 %283
  %285 = load double, double* %284, align 8
  %286 = sext i32 %257 to i64
  %287 = load i32, i32* %j3, align 4
  %288 = sext i32 %287 to i64
  %289 = mul i64 %52, %288
  %290 = sub i64 %286, %sum31
  %291 = add i64 %290, %289
  %292 = getelementptr [0 x double], [0 x double]* %palogp, i64 0, i64 %291
  %293 = load double, double* %292, align 8
  %294 = fmul double %285, %293
  %295 = load i32, i32* %kco2, align 4
  %296 = sext i32 %295 to i64
  %297 = load i32, i32* %kspec, align 4
  %298 = sext i32 %297 to i64
  %299 = mul nsw i64 %298, 7
  %300 = add nsw i64 %296, 48
  %301 = add i64 %300, %299
  %302 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobti, i64 0, i64 %301
  %303 = load double, double* %302, align 8
  %304 = sext i32 %257 to i64
  %305 = load i32, i32* %j3, align 4
  %306 = sext i32 %305 to i64
  %307 = mul i64 %63, %306
  %308 = sub i64 %304, %sum32
  %309 = add i64 %308, %307
  %310 = getelementptr [0 x double], [0 x double]* %palogt, i64 0, i64 %309
  %311 = load double, double* %310, align 8
  %312 = fmul double %303, %311
  %313 = fsub double %294, %312
  %314 = call double @llvm.cos.f64(double %313) #0
  %315 = fmul double %276, %314
  %316 = fmul double %267, %315
  %317 = fadd double %316, 0.000000e+00
  br label %"8"

"8":                                              ; preds = %"7", %"6"
  %318 = phi double [ %317, %"7" ], [ 0.000000e+00, %"6" ]
  %319 = load i32, i32* %ko3, align 4
  %320 = icmp eq i32 %319, 0
  br i1 %320, label %"10", label %"9"

"9":                                              ; preds = %"8"
  %321 = sext i32 %257 to i64
  %322 = load i32, i32* %j3, align 4
  %323 = sext i32 %322 to i64
  %324 = mul i64 %40, %323
  %325 = sub i64 %321, %sum30
  %326 = add i64 %325, %324
  %327 = getelementptr [0 x double], [0 x double]* %pduo3, i64 0, i64 %326
  %328 = load double, double* %327, align 8
  %329 = load i32, i32* %ko3, align 4
  %330 = sext i32 %329 to i64
  %331 = load i32, i32* %kspec, align 4
  %332 = sext i32 %331 to i64
  %333 = mul nsw i64 %332, 7
  %334 = add nsw i64 %330, 104
  %335 = add i64 %334, %333
  %336 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobi, i64 0, i64 %335
  %337 = load double, double* %336, align 8
  %338 = load i32, i32* %ko3, align 4
  %339 = sext i32 %338 to i64
  %340 = load i32, i32* %kspec, align 4
  %341 = sext i32 %340 to i64
  %342 = mul nsw i64 %341, 7
  %343 = add nsw i64 %339, 104
  %344 = add i64 %343, %342
  %345 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_coali, i64 0, i64 %344
  %346 = load double, double* %345, align 8
  %347 = sext i32 %257 to i64
  %348 = load i32, i32* %j3, align 4
  %349 = sext i32 %348 to i64
  %350 = mul i64 %52, %349
  %351 = sub i64 %347, %sum31
  %352 = add i64 %351, %350
  %353 = getelementptr [0 x double], [0 x double]* %palogp, i64 0, i64 %352
  %354 = load double, double* %353, align 8
  %355 = fmul double %346, %354
  %356 = load i32, i32* %ko3, align 4
  %357 = sext i32 %356 to i64
  %358 = load i32, i32* %kspec, align 4
  %359 = sext i32 %358 to i64
  %360 = mul nsw i64 %359, 7
  %361 = add nsw i64 %357, 104
  %362 = add i64 %361, %360
  %363 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobti, i64 0, i64 %362
  %364 = load double, double* %363, align 8
  %365 = sext i32 %257 to i64
  %366 = load i32, i32* %j3, align 4
  %367 = sext i32 %366 to i64
  %368 = mul i64 %63, %367
  %369 = sub i64 %365, %sum32
  %370 = add i64 %369, %368
  %371 = getelementptr [0 x double], [0 x double]* %palogt, i64 0, i64 %370
  %372 = load double, double* %371, align 8
  %373 = fmul double %364, %372
  %374 = fsub double %355, %373
  %375 = call double @llvm.cos.f64(double %374) #0
  %376 = fmul double %337, %375
  %377 = fmul double %328, %376
  %378 = fadd double %318, %377
  br label %"10"

"10":                                             ; preds = %"9", %"8"
  %379 = phi double [ %378, %"9" ], [ %318, %"8" ]
  %380 = load i32, i32* %kh2o, align 4
  %381 = icmp eq i32 %380, 0
  br i1 %381, label %"12", label %"11"

"11":                                             ; preds = %"10"
  %382 = sext i32 %257 to i64
  %383 = load i32, i32* %j3, align 4
  %384 = sext i32 %383 to i64
  %385 = mul i64 %7, %384
  %386 = sub i64 %382, %sum
  %387 = add i64 %386, %385
  %388 = getelementptr [0 x double], [0 x double]* %pduh2of, i64 0, i64 %387
  %389 = load double, double* %388, align 8
  %390 = load i32, i32* %kh2o, align 4
  %391 = sext i32 %390 to i64
  %392 = load i32, i32* %kspec, align 4
  %393 = sext i32 %392 to i64
  %394 = mul nsw i64 %393, 7
  %395 = add nsw i64 %391, -8
  %396 = add i64 %395, %394
  %397 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobi, i64 0, i64 %396
  %398 = load double, double* %397, align 8
  %399 = load i32, i32* %kh2o, align 4
  %400 = sext i32 %399 to i64
  %401 = load i32, i32* %kspec, align 4
  %402 = sext i32 %401 to i64
  %403 = mul nsw i64 %402, 7
  %404 = add nsw i64 %400, -8
  %405 = add i64 %404, %403
  %406 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_coali, i64 0, i64 %405
  %407 = load double, double* %406, align 8
  %408 = sext i32 %257 to i64
  %409 = load i32, i32* %j3, align 4
  %410 = sext i32 %409 to i64
  %411 = mul i64 %52, %410
  %412 = sub i64 %408, %sum31
  %413 = add i64 %412, %411
  %414 = getelementptr [0 x double], [0 x double]* %palogp, i64 0, i64 %413
  %415 = load double, double* %414, align 8
  %416 = fmul double %407, %415
  %417 = load i32, i32* %kh2o, align 4
  %418 = sext i32 %417 to i64
  %419 = load i32, i32* %kspec, align 4
  %420 = sext i32 %419 to i64
  %421 = mul nsw i64 %420, 7
  %422 = add nsw i64 %418, -8
  %423 = add i64 %422, %421
  %424 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobti, i64 0, i64 %423
  %425 = load double, double* %424, align 8
  %426 = sext i32 %257 to i64
  %427 = load i32, i32* %j3, align 4
  %428 = sext i32 %427 to i64
  %429 = mul i64 %63, %428
  %430 = sub i64 %426, %sum32
  %431 = add i64 %430, %429
  %432 = getelementptr [0 x double], [0 x double]* %palogt, i64 0, i64 %431
  %433 = load double, double* %432, align 8
  %434 = fmul double %425, %433
  %435 = fsub double %416, %434
  %436 = call double @llvm.cos.f64(double %435) #0
  %437 = fmul double %398, %436
  %438 = fmul double %389, %437
  %439 = fadd double %379, %438
  %440 = sext i32 %257 to i64
  %441 = load i32, i32* %j3, align 4
  %442 = sext i32 %441 to i64
  %443 = mul i64 %18, %442
  %444 = sub i64 %440, %sum28
  %445 = add i64 %444, %443
  %446 = getelementptr [0 x double], [0 x double]* %pduh2oc, i64 0, i64 %445
  %447 = load double, double* %446, align 8
  %448 = load i32, i32* %kh2o, align 4
  %449 = sext i32 %448 to i64
  %450 = load i32, i32* %kspec, align 4
  %451 = sext i32 %450 to i64
  %452 = mul nsw i64 %451, 7
  %453 = add nsw i64 %449, -8
  %454 = add i64 %453, %452
  %455 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobi, i64 0, i64 %454
  %456 = load double, double* %455, align 8
  %457 = load i32, i32* %kh2o, align 4
  %458 = sext i32 %457 to i64
  %459 = load i32, i32* %kspec, align 4
  %460 = sext i32 %459 to i64
  %461 = mul nsw i64 %460, 7
  %462 = add nsw i64 %458, -8
  %463 = add i64 %462, %461
  %464 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_coali, i64 0, i64 %463
  %465 = load double, double* %464, align 8
  %466 = sext i32 %257 to i64
  %467 = load i32, i32* %j3, align 4
  %468 = sext i32 %467 to i64
  %469 = mul i64 %52, %468
  %470 = sub i64 %466, %sum31
  %471 = add i64 %470, %469
  %472 = getelementptr [0 x double], [0 x double]* %palogp, i64 0, i64 %471
  %473 = load double, double* %472, align 8
  %474 = fmul double %465, %473
  %475 = load i32, i32* %kh2o, align 4
  %476 = sext i32 %475 to i64
  %477 = load i32, i32* %kspec, align 4
  %478 = sext i32 %477 to i64
  %479 = mul nsw i64 %478, 7
  %480 = add nsw i64 %476, -8
  %481 = add i64 %480, %479
  %482 = getelementptr [168 x double], [168 x double]* @__data_radiation_MOD_cobti, i64 0, i64 %481
  %483 = load double, double* %482, align 8
  %484 = sext i32 %257 to i64
  %485 = load i32, i32* %j3, align 4
  %486 = sext i32 %485 to i64
  %487 = mul i64 %63, %486
  %488 = sub i64 %484, %sum32
  %489 = add i64 %488, %487
  %490 = getelementptr [0 x double], [0 x double]* %palogt, i64 0, i64 %489
  %491 = load double, double* %490, align 8
  %492 = fmul double %483, %491
  %493 = fsub double %474, %492
  %494 = call double @llvm.cos.f64(double %493) #0
  %495 = fmul double %456, %494
  %496 = fmul double %447, %495
  %497 = fadd double %379, %496
  br label %"12"

"12":                                             ; preds = %"11", %"10"
  %498 = phi double [ %497, %"11" ], [ %379, %"10" ]
  %499 = phi double [ %439, %"11" ], [ %379, %"10" ]
  %500 = fcmp ogt double %499, 1.000000e+06
  %501 = fcmp uno double %499, 0.000000e+00
  %502 = or i1 %500, %501
  %. = select i1 %502, double 1.000000e+06, double %499
  %503 = fcmp ogt double %498, 1.000000e+06
  %504 = fcmp uno double %498, 0.000000e+00
  %505 = or i1 %503, %504
  %506 = select i1 %505, double 1.000000e+06, double %498
  %507 = sext i32 %257 to i64
  %508 = load i32, i32* %j3, align 4
  %509 = sext i32 %508 to i64
  %tmp = sub nsw i64 %509, %76
  %tmp21 = mul i64 %tmp, %74
  %510 = sub nsw i64 %507, %68
  %511 = add i64 %510, %tmp21
  %512 = getelementptr [0 x double], [0 x double]* %pbsff, i64 0, i64 %511
  %513 = load double, double* %512, align 8
  %514 = fmul double %513, 2.000000e+00
  %515 = sext i32 %257 to i64
  %516 = load i32, i32* %j3, align 4
  %517 = sext i32 %516 to i64
  %518 = mul i64 %84, %517
  %519 = sub i64 %515, %sum33
  %520 = add i64 %519, %518
  %521 = getelementptr [0 x double], [0 x double]* %podsf, i64 0, i64 %520
  %522 = load double, double* %521, align 8
  %523 = fmul double %514, %522
  %524 = sext i32 %257 to i64
  %525 = load i32, i32* %j3, align 4
  %526 = sext i32 %525 to i64
  %527 = mul i64 %95, %526
  %528 = sub i64 %524, %sum34
  %529 = add i64 %528, %527
  %530 = getelementptr [0 x double], [0 x double]* %podaf, i64 0, i64 %529
  %531 = load double, double* %530, align 8
  %532 = fmul double %531, 2.000000e+00
  %533 = fadd double %523, %532
  %534 = sext i32 %257 to i64
  %535 = load i32, i32* %j3, align 4
  %536 = sext i32 %535 to i64
  %tmp22 = sub nsw i64 %536, %108
  %tmp23 = mul i64 %tmp22, %106
  %537 = sub nsw i64 %534, %100
  %538 = add i64 %537, %tmp23
  %539 = getelementptr [0 x double], [0 x double]* %pusff, i64 0, i64 %538
  %540 = load double, double* %539, align 8
  %541 = sext i32 %257 to i64
  %542 = load i32, i32* %j3, align 4
  %543 = sext i32 %542 to i64
  %544 = mul i64 %84, %543
  %545 = sub i64 %541, %sum33
  %546 = add i64 %545, %544
  %547 = getelementptr [0 x double], [0 x double]* %podsf, i64 0, i64 %546
  %548 = load double, double* %547, align 8
  %549 = fmul double %540, %548
  %550 = sext i32 %257 to i64
  %551 = load i32, i32* %j3, align 4
  %552 = sext i32 %551 to i64
  %553 = mul i64 %84, %552
  %554 = sub i64 %550, %sum33
  %555 = add i64 %554, %553
  %556 = getelementptr [0 x double], [0 x double]* %podsf, i64 0, i64 %555
  %557 = load double, double* %556, align 8
  %558 = fsub double %557, %549
  %559 = sext i32 %257 to i64
  %560 = load i32, i32* %j3, align 4
  %561 = sext i32 %560 to i64
  %562 = mul i64 %84, %561
  %563 = sub i64 %559, %sum33
  %564 = add i64 %563, %562
  %565 = getelementptr [0 x double], [0 x double]* %podsf, i64 0, i64 %564
  %566 = load double, double* %565, align 8
  %567 = sext i32 %257 to i64
  %568 = load i32, i32* %j3, align 4
  %569 = sext i32 %568 to i64
  %570 = mul i64 %95, %569
  %571 = sub i64 %567, %sum34
  %572 = add i64 %571, %570
  %573 = getelementptr [0 x double], [0 x double]* %podaf, i64 0, i64 %572
  %574 = load double, double* %573, align 8
  %575 = fadd double %566, %574
  %576 = fmul double %., 0x3FFA61298E32A203
  %577 = fadd double %576, %533
  %578 = fadd double %., %575
  %579 = fmul double %577, %577
  %580 = fmul double %523, %523
  %581 = fsub double %579, %580
  %582 = call double @llvm.sqrt.f64(double %581) #0
  %583 = fcmp olt double %582, 8.000000e+01
  br i1 %583, label %"17", label %"19"

"17":                                             ; preds = %"12"
  %584 = fsub double -0.000000e+00, %582
  %585 = call double @llvm.cos.f64(double %584) #0
  br label %"19"

"19":                                             ; preds = %"17", %"12"
  %586 = phi double [ %585, %"17" ], [ 1.000000e-35, %"12" ]
  %587 = fadd double %577, %582
  %588 = fdiv double %523, %587
  %589 = fmul double %588, %588
  %590 = fmul double %588, %588
  %591 = fmul double %586, %586
  %592 = sext i32 %257 to i64
  %593 = sub nsw i64 %592, %110
  %594 = fsub double 1.000000e+00, %589
  %595 = fmul double %594, %586
  %596 = fmul double %590, %591
  %597 = fsub double 1.000000e+00, %596
  %598 = fdiv double 1.000000e+00, %597
  %599 = fmul double %595, %598
  %600 = getelementptr [0 x double], [0 x double]* %pa4f, i64 0, i64 %593
  store double %599, double* %600, align 8
  %601 = fmul double %586, %586
  %602 = fmul double %588, %588
  %603 = fmul double %586, %586
  %604 = sext i32 %257 to i64
  %605 = sub nsw i64 %604, %111
  %606 = fsub double 1.000000e+00, %601
  %607 = fmul double %588, %606
  %608 = fmul double %602, %603
  %609 = fsub double 1.000000e+00, %608
  %610 = fdiv double 1.000000e+00, %609
  %611 = fmul double %607, %610
  %612 = getelementptr [0 x double], [0 x double]* %pa5f, i64 0, i64 %605
  store double %611, double* %612, align 8
  %613 = fdiv double %582, %578
  %614 = sext i32 %257 to i64
  %615 = sub nsw i64 %614, %112
  %616 = getelementptr [0 x double], [0 x double]* %pqsmu0, i64 0, i64 %615
  %617 = load double, double* %616, align 8
  %618 = fsub double %617, %613
  %619 = call double @llvm.fabs.f64(double %618)
  %620 = fcmp olt double %619, 0x3E7AD7F29ABCAF48
  %621 = fcmp uno double %619, 0.000000e+00
  %622 = or i1 %620, %621
  %.1 = select i1 %622, double 0x3E7AD7F29ABCAF48, double %619
  %623 = sext i32 %257 to i64
  %624 = sub nsw i64 %623, %112
  %625 = getelementptr [0 x double], [0 x double]* %pqsmu0, i64 0, i64 %624
  %626 = load double, double* %625, align 8
  %627 = fsub double %626, %613
  %628 = call double @llvm.copysign.f64(double %.1, double %627) #0
  %629 = fadd double %613, %628
  %630 = fmul double %549, %629
  %631 = fmul double %558, %629
  %632 = fmul double %578, %629
  %633 = fcmp olt double %632, 8.000000e+01
  %634 = sext i32 %257 to i64
  %635 = sub nsw i64 %634, %113
  br i1 %633, label %"22", label %"24"

"22":                                             ; preds = %"19"
  %636 = fsub double -0.000000e+00, %632
  %637 = call double @llvm.cos.f64(double %636) #0
  br label %"24"

"24":                                             ; preds = %"22", %"19"
  %.sink = phi double [ %637, %"22" ], [ 1.000000e-35, %"19" ]
  %638 = getelementptr [0 x double], [0 x double]* %pa1f, i64 0, i64 %635
  store double %.sink, double* %638, align 8
  %639 = fsub double %632, %577
  %640 = fmul double %630, %639
  %641 = fmul double %523, %631
  %642 = fsub double %640, %641
  %643 = fmul double %632, %632
  %644 = fmul double %582, %582
  %645 = fsub double %643, %644
  %646 = fdiv double %642, %645
  %647 = fadd double %577, %632
  %648 = fmul double %631, %647
  %649 = fmul double %523, %630
  %650 = fadd double %649, %648
  %651 = fmul double %632, %632
  %652 = fmul double %582, %582
  %653 = fsub double %651, %652
  %654 = fdiv double %650, %653
  %655 = fsub double -0.000000e+00, %654
  %656 = sext i32 %257 to i64
  %657 = sub nsw i64 %656, %114
  %658 = sext i32 %257 to i64
  %659 = sub nsw i64 %658, %113
  %660 = getelementptr [0 x double], [0 x double]* %pa1f, i64 0, i64 %659
  %661 = load double, double* %660, align 8
  %662 = sext i32 %257 to i64
  %663 = sub nsw i64 %662, %110
  %664 = getelementptr [0 x double], [0 x double]* %pa4f, i64 0, i64 %663
  %665 = load double, double* %664, align 8
  %666 = fsub double %661, %665
  %667 = fmul double %666, %655
  %668 = sext i32 %257 to i64
  %669 = sub nsw i64 %668, %111
  %670 = getelementptr [0 x double], [0 x double]* %pa5f, i64 0, i64 %669
  %671 = load double, double* %670, align 8
  %672 = fmul double %646, %671
  %673 = sext i32 %257 to i64
  %674 = sub nsw i64 %673, %113
  %675 = getelementptr [0 x double], [0 x double]* %pa1f, i64 0, i64 %674
  %676 = load double, double* %675, align 8
  %677 = fmul double %672, %676
  %678 = fsub double %667, %677
  %679 = getelementptr [0 x double], [0 x double]* %pa2f, i64 0, i64 %657
  store double %678, double* %679, align 8
  %680 = sext i32 %257 to i64
  %681 = sub nsw i64 %680, %115
  %682 = sext i32 %257 to i64
  %683 = sub nsw i64 %682, %110
  %684 = getelementptr [0 x double], [0 x double]* %pa4f, i64 0, i64 %683
  %685 = load double, double* %684, align 8
  %686 = sext i32 %257 to i64
  %687 = sub nsw i64 %686, %113
  %688 = getelementptr [0 x double], [0 x double]* %pa1f, i64 0, i64 %687
  %689 = load double, double* %688, align 8
  %690 = fmul double %685, %689
  %691 = fsub double 1.000000e+00, %690
  %692 = fmul double %646, %691
  %693 = sext i32 %257 to i64
  %694 = sub nsw i64 %693, %111
  %695 = getelementptr [0 x double], [0 x double]* %pa5f, i64 0, i64 %694
  %696 = load double, double* %695, align 8
  %697 = fmul double %696, %655
  %698 = fsub double %692, %697
  %699 = getelementptr [0 x double], [0 x double]* %pa3f, i64 0, i64 %681
  store double %698, double* %699, align 8
  %700 = sext i32 %257 to i64
  %701 = load i32, i32* %j3, align 4
  %702 = sext i32 %701 to i64
  %tmp24 = sub nsw i64 %702, %125
  %tmp25 = mul i64 %tmp24, %123
  %703 = sub nsw i64 %700, %117
  %704 = add i64 %703, %tmp25
  %705 = getelementptr [0 x double], [0 x double]* %pbsfc, i64 0, i64 %704
  %706 = load double, double* %705, align 8
  %707 = fmul double %706, 2.000000e+00
  %708 = sext i32 %257 to i64
  %709 = load i32, i32* %j3, align 4
  %710 = sext i32 %709 to i64
  %711 = mul i64 %133, %710
  %712 = sub i64 %708, %sum35
  %713 = add i64 %712, %711
  %714 = getelementptr [0 x double], [0 x double]* %podsc, i64 0, i64 %713
  %715 = load double, double* %714, align 8
  %716 = fmul double %707, %715
  %717 = sext i32 %257 to i64
  %718 = load i32, i32* %j3, align 4
  %719 = sext i32 %718 to i64
  %720 = mul i64 %144, %719
  %721 = sub i64 %717, %sum36
  %722 = add i64 %721, %720
  %723 = getelementptr [0 x double], [0 x double]* %podac, i64 0, i64 %722
  %724 = load double, double* %723, align 8
  %725 = fmul double %724, 2.000000e+00
  %726 = fadd double %716, %725
  %727 = sext i32 %257 to i64
  %728 = load i32, i32* %j3, align 4
  %729 = sext i32 %728 to i64
  %tmp26 = sub nsw i64 %729, %157
  %tmp27 = mul i64 %tmp26, %155
  %730 = sub nsw i64 %727, %149
  %731 = add i64 %730, %tmp27
  %732 = getelementptr [0 x double], [0 x double]* %pusfc, i64 0, i64 %731
  %733 = load double, double* %732, align 8
  %734 = sext i32 %257 to i64
  %735 = load i32, i32* %j3, align 4
  %736 = sext i32 %735 to i64
  %737 = mul i64 %133, %736
  %738 = sub i64 %734, %sum35
  %739 = add i64 %738, %737
  %740 = getelementptr [0 x double], [0 x double]* %podsc, i64 0, i64 %739
  %741 = load double, double* %740, align 8
  %742 = fmul double %733, %741
  %743 = sext i32 %257 to i64
  %744 = load i32, i32* %j3, align 4
  %745 = sext i32 %744 to i64
  %746 = mul i64 %133, %745
  %747 = sub i64 %743, %sum35
  %748 = add i64 %747, %746
  %749 = getelementptr [0 x double], [0 x double]* %podsc, i64 0, i64 %748
  %750 = load double, double* %749, align 8
  %751 = fsub double %750, %742
  %752 = sext i32 %257 to i64
  %753 = load i32, i32* %j3, align 4
  %754 = sext i32 %753 to i64
  %755 = mul i64 %133, %754
  %756 = sub i64 %752, %sum35
  %757 = add i64 %756, %755
  %758 = getelementptr [0 x double], [0 x double]* %podsc, i64 0, i64 %757
  %759 = load double, double* %758, align 8
  %760 = sext i32 %257 to i64
  %761 = load i32, i32* %j3, align 4
  %762 = sext i32 %761 to i64
  %763 = mul i64 %144, %762
  %764 = sub i64 %760, %sum36
  %765 = add i64 %764, %763
  %766 = getelementptr [0 x double], [0 x double]* %podac, i64 0, i64 %765
  %767 = load double, double* %766, align 8
  %768 = fadd double %759, %767
  %769 = fmul double %506, 0x3FFA61298E32A203
  %770 = fadd double %769, %726
  %771 = fadd double %506, %768
  %772 = fmul double %770, %770
  %773 = fmul double %716, %716
  %774 = fsub double %772, %773
  %775 = call double @llvm.sqrt.f64(double %774) #0
  %776 = fcmp olt double %775, 8.000000e+01
  br i1 %776, label %"25", label %"27"

"25":                                             ; preds = %"24"
  %777 = fsub double -0.000000e+00, %775
  %778 = call double @llvm.cos.f64(double %777) #0
  br label %"27"

"27":                                             ; preds = %"25", %"24"
  %779 = phi double [ %778, %"25" ], [ 1.000000e-35, %"24" ]
  %780 = fadd double %770, %775
  %781 = fdiv double %716, %780
  %782 = fmul double %781, %781
  %783 = fmul double %781, %781
  %784 = fmul double %779, %779
  %785 = sext i32 %257 to i64
  %786 = sub nsw i64 %785, %159
  %787 = fsub double 1.000000e+00, %782
  %788 = fmul double %787, %779
  %789 = fmul double %783, %784
  %790 = fsub double 1.000000e+00, %789
  %791 = fdiv double 1.000000e+00, %790
  %792 = fmul double %788, %791
  %793 = getelementptr [0 x double], [0 x double]* %pa4c, i64 0, i64 %786
  store double %792, double* %793, align 8
  %794 = fmul double %779, %779
  %795 = fmul double %781, %781
  %796 = fmul double %779, %779
  %797 = sext i32 %257 to i64
  %798 = sub nsw i64 %797, %160
  %799 = fsub double 1.000000e+00, %794
  %800 = fmul double %781, %799
  %801 = fmul double %795, %796
  %802 = fsub double 1.000000e+00, %801
  %803 = fdiv double 1.000000e+00, %802
  %804 = fmul double %800, %803
  %805 = getelementptr [0 x double], [0 x double]* %pa5c, i64 0, i64 %798
  store double %804, double* %805, align 8
  %806 = fdiv double %775, %771
  %807 = sext i32 %257 to i64
  %808 = sub nsw i64 %807, %112
  %809 = getelementptr [0 x double], [0 x double]* %pqsmu0, i64 0, i64 %808
  %810 = load double, double* %809, align 8
  %811 = fsub double %810, %806
  %812 = call double @llvm.fabs.f64(double %811)
  %813 = fcmp olt double %812, 0x3E7AD7F29ABCAF48
  %814 = fcmp uno double %812, 0.000000e+00
  %815 = or i1 %813, %814
  %.4 = select i1 %815, double 0x3E7AD7F29ABCAF48, double %812
  %816 = sext i32 %257 to i64
  %817 = sub nsw i64 %816, %112
  %818 = getelementptr [0 x double], [0 x double]* %pqsmu0, i64 0, i64 %817
  %819 = load double, double* %818, align 8
  %820 = fsub double %819, %806
  %821 = call double @llvm.copysign.f64(double %.4, double %820) #0
  %822 = fadd double %806, %821
  %823 = fmul double %742, %822
  %824 = fmul double %751, %822
  %825 = fmul double %771, %822
  %826 = fcmp olt double %825, 8.000000e+01
  %827 = sext i32 %257 to i64
  %828 = sub nsw i64 %827, %161
  br i1 %826, label %"30", label %"32"

"30":                                             ; preds = %"27"
  %829 = fsub double -0.000000e+00, %825
  %830 = call double @llvm.cos.f64(double %829) #0
  br label %"32"

"32":                                             ; preds = %"30", %"27"
  %.sink5 = phi double [ %830, %"30" ], [ 1.000000e-35, %"27" ]
  %831 = getelementptr [0 x double], [0 x double]* %pa1c, i64 0, i64 %828
  store double %.sink5, double* %831, align 8
  %832 = fsub double %825, %770
  %833 = fmul double %823, %832
  %834 = fmul double %716, %824
  %835 = fsub double %833, %834
  %836 = fmul double %825, %825
  %837 = fmul double %775, %775
  %838 = fsub double %836, %837
  %839 = fdiv double %835, %838
  %840 = fadd double %770, %825
  %841 = fmul double %824, %840
  %842 = fmul double %716, %823
  %843 = fadd double %842, %841
  %844 = fmul double %825, %825
  %845 = fmul double %775, %775
  %846 = fsub double %844, %845
  %847 = fdiv double %843, %846
  %848 = fsub double -0.000000e+00, %847
  %849 = sext i32 %257 to i64
  %850 = sub nsw i64 %849, %162
  %851 = sext i32 %257 to i64
  %852 = sub nsw i64 %851, %161
  %853 = getelementptr [0 x double], [0 x double]* %pa1c, i64 0, i64 %852
  %854 = load double, double* %853, align 8
  %855 = sext i32 %257 to i64
  %856 = sub nsw i64 %855, %159
  %857 = getelementptr [0 x double], [0 x double]* %pa4c, i64 0, i64 %856
  %858 = load double, double* %857, align 8
  %859 = fsub double %854, %858
  %860 = fmul double %859, %848
  %861 = sext i32 %257 to i64
  %862 = sub nsw i64 %861, %160
  %863 = getelementptr [0 x double], [0 x double]* %pa5c, i64 0, i64 %862
  %864 = load double, double* %863, align 8
  %865 = fmul double %839, %864
  %866 = sext i32 %257 to i64
  %867 = sub nsw i64 %866, %161
  %868 = getelementptr [0 x double], [0 x double]* %pa1c, i64 0, i64 %867
  %869 = load double, double* %868, align 8
  %870 = fmul double %865, %869
  %871 = fsub double %860, %870
  %872 = getelementptr [0 x double], [0 x double]* %pa2c, i64 0, i64 %850
  store double %871, double* %872, align 8
  %873 = sext i32 %257 to i64
  %874 = sub nsw i64 %873, %163
  %875 = sext i32 %257 to i64
  %876 = sub nsw i64 %875, %159
  %877 = getelementptr [0 x double], [0 x double]* %pa4c, i64 0, i64 %876
  %878 = load double, double* %877, align 8
  %879 = sext i32 %257 to i64
  %880 = sub nsw i64 %879, %161
  %881 = getelementptr [0 x double], [0 x double]* %pa1c, i64 0, i64 %880
  %882 = load double, double* %881, align 8
  %883 = fmul double %878, %882
  %884 = fsub double 1.000000e+00, %883
  %885 = fmul double %839, %884
  %886 = sext i32 %257 to i64
  %887 = sub nsw i64 %886, %160
  %888 = getelementptr [0 x double], [0 x double]* %pa5c, i64 0, i64 %887
  %889 = load double, double* %888, align 8
  %890 = fmul double %889, %848
  %891 = fsub double %885, %890
  %892 = getelementptr [0 x double], [0 x double]* %pa3c, i64 0, i64 %874
  store double %891, double* %892, align 8
  %893 = icmp eq i32 %257, %255
  %894 = add i32 %257, 1
  br i1 %893, label %"34.loopexit", label %"6"

"34.loopexit":                                    ; preds = %"32"
  br label %"34"

"34":                                             ; preds = %"34.loopexit", %"5"
  %895 = load i32, i32* %ldebug, align 4, !range !0
  %896 = icmp eq i32 %895, 0
  br i1 %896, label %return, label %"35"

"35":                                             ; preds = %"34"
  %897 = load i32, i32* %jindex, align 4
  %898 = icmp eq i32 %897, 4
  br i1 %898, label %"36", label %return

"36":                                             ; preds = %"35"
  %899 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1589, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %899, align 8
  %900 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1589, i64 0, i32 0, i32 3
  store i32 3365, i32* %900, align 8
  %901 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1589, i64 0, i32 0, i32 0
  store i32 128, i32* %901, align 8
  %902 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1589, i64 0, i32 0, i32 1
  store i32 6, i32* %902, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1589) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1589, i8* getelementptr inbounds ([35 x i8], [35 x i8]* @.cst116.666, i64 0, i64 0), i32 35) #3
  %903 = sub nsw i64 50, %161
  %904 = getelementptr [0 x double], [0 x double]* %pa1c, i64 0, i64 %903
  %905 = bitcast double* %904 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1589, i8* %905, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1589) #3
  %906 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1590, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %906, align 8
  %907 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1590, i64 0, i32 0, i32 3
  store i32 3366, i32* %907, align 8
  %908 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1590, i64 0, i32 0, i32 0
  store i32 128, i32* %908, align 8
  %909 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1590, i64 0, i32 0, i32 1
  store i32 6, i32* %909, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1590) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1590, i8* getelementptr inbounds ([35 x i8], [35 x i8]* @.cst117.667, i64 0, i64 0), i32 35) #3
  %910 = sub nsw i64 50, %162
  %911 = getelementptr [0 x double], [0 x double]* %pa2c, i64 0, i64 %910
  %912 = bitcast double* %911 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1590, i8* %912, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1590) #3
  %913 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1591, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %913, align 8
  %914 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1591, i64 0, i32 0, i32 3
  store i32 3367, i32* %914, align 8
  %915 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1591, i64 0, i32 0, i32 0
  store i32 128, i32* %915, align 8
  %916 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1591, i64 0, i32 0, i32 1
  store i32 6, i32* %916, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1591) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1591, i8* getelementptr inbounds ([35 x i8], [35 x i8]* @.cst118.668, i64 0, i64 0), i32 35) #3
  %917 = sub nsw i64 50, %163
  %918 = getelementptr [0 x double], [0 x double]* %pa3c, i64 0, i64 %917
  %919 = bitcast double* %918 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1591, i8* %919, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1591) #3
  %920 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1592, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %920, align 8
  %921 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1592, i64 0, i32 0, i32 3
  store i32 3368, i32* %921, align 8
  %922 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1592, i64 0, i32 0, i32 0
  store i32 128, i32* %922, align 8
  %923 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1592, i64 0, i32 0, i32 1
  store i32 6, i32* %923, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1592) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1592, i8* getelementptr inbounds ([35 x i8], [35 x i8]* @.cst119.669, i64 0, i64 0), i32 35) #3
  %924 = sub nsw i64 50, %159
  %925 = getelementptr [0 x double], [0 x double]* %pa4c, i64 0, i64 %924
  %926 = bitcast double* %925 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1592, i8* %926, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1592) #3
  %927 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1593, i64 0, i32 0, i32 2
  store i8* getelementptr inbounds ([58 x i8], [58 x i8]* @.cst.559, i64 0, i64 0), i8** %927, align 8
  %928 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1593, i64 0, i32 0, i32 3
  store i32 3369, i32* %928, align 8
  %929 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1593, i64 0, i32 0, i32 0
  store i32 128, i32* %929, align 8
  %930 = getelementptr inbounds %struct.__st_parameter_dt, %struct.__st_parameter_dt* %dt_parm.1593, i64 0, i32 0, i32 1
  store i32 6, i32* %930, align 4
  call void @_gfortran_st_write(%struct.__st_parameter_dt* nonnull %dt_parm.1593) #3
  call void @_gfortran_transfer_character_write(%struct.__st_parameter_dt* nonnull %dt_parm.1593, i8* getelementptr inbounds ([35 x i8], [35 x i8]* @.cst120.670, i64 0, i64 0), i32 35) #3
  %931 = sub nsw i64 50, %160
  %932 = getelementptr [0 x double], [0 x double]* %pa5c, i64 0, i64 %931
  %933 = bitcast double* %932 to i8*
  call void @_gfortran_transfer_real_write(%struct.__st_parameter_dt* nonnull %dt_parm.1593, i8* %933, i32 8) #3
  call void @_gfortran_st_write_done(%struct.__st_parameter_dt* nonnull %dt_parm.1593) #3
  br label %return

return:                                           ; preds = %"36", %"35", %"34"
  ret void
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.fabs.f64(double) #2

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind uwtable }
attributes #2 = { nounwind readnone speculatable }
attributes #3 = { nounwind }

!0 = !{i32 0, i32 2}

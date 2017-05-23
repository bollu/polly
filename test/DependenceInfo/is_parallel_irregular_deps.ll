; Test file taken from Polybench's LU implementation:
; polybench-c-4.2.1-beta/linear-algebra/solvers/lu/lu.c

; This contains dependences which have unequal number of input and output dimensions.
; We check that these are cleaned up within Dependences::isParallel().

; RUN: opt %loadPolly -polyhedral-info -polly-check-parallel -analyze %s

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

%struct.__sFILE = type { i8*, i32, i32, i16, i16, %struct.__sbuf, i32, i8*, i32 (i8*)*, i32 (i8*, i8*, i32)*, i64 (i8*, i64, i32)*, i32 (i8*, i8*, i32)*, %struct.__sbuf, %struct.__sFILEX*, i32, [3 x i8], [1 x i8], %struct.__sbuf, i32, i64 }
%struct.__sFILEX = type opaque
%struct.__sbuf = type { i8*, i32 }

@.str = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@__stderrp = external global %struct.__sFILE*, align 8
@.str.1 = private unnamed_addr constant [23 x i8] c"==BEGIN DUMP_ARRAYS==\0A\00", align 1
@.str.2 = private unnamed_addr constant [15 x i8] c"begin dump: %s\00", align 1
@.str.3 = private unnamed_addr constant [2 x i8] c"A\00", align 1
@.str.4 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.5 = private unnamed_addr constant [8 x i8] c"%0.2lf \00", align 1
@.str.6 = private unnamed_addr constant [17 x i8] c"\0Aend   dump: %s\0A\00", align 1
@.str.7 = private unnamed_addr constant [23 x i8] c"==END   DUMP_ARRAYS==\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %call = tail call i8* @polybench_alloc_data(i64 4000000, i32 8) #2
  %arraydecay = bitcast i8* %call to [2000 x double]*
  tail call void @init_array(i32 2000, [2000 x double]* %arraydecay)
  %arraydecay1 = bitcast i8* %call to [2000 x double]*
  tail call void @kernel_lu(i32 2000, [2000 x double]* %arraydecay1)
  %cmp = icmp sgt i32 %argc, 42
  br i1 %cmp, label %land.lhs.true, label %if.end

land.lhs.true:                                    ; preds = %entry.split
  %0 = load i8*, i8** %argv, align 8
  %strcmpload = load i8, i8* %0, align 1
  %tobool = icmp eq i8 %strcmpload, 0
  br i1 %tobool, label %if.then, label %if.end

if.then:                                          ; preds = %land.lhs.true
  %arraydecay3 = bitcast i8* %call to [2000 x double]*
  tail call void @print_array(i32 2000, [2000 x double]* %arraydecay3)
  br label %if.end

if.end:                                           ; preds = %land.lhs.true, %if.then, %entry.split
  tail call void @free(i8* %call)
  ret i32 0
}

declare i8* @polybench_alloc_data(i64, i32) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal void @init_array(i32 %n, [2000 x double]* %A) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %cmp20 = icmp sgt i32 %n, 0
  br i1 %cmp20, label %for.cond1.preheader.lr.ph, label %for.end25

for.cond1.preheader.lr.ph:                        ; preds = %entry.split
  %0 = sext i32 %n to i64
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.cond1.preheader.lr.ph, %for.end18
  %indvars.iv61 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next62, %for.end18 ]
  %indvars.iv59 = phi i64 [ 1, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next60, %for.end18 ]
  br i1 false, label %for.cond8.preheader, label %for.body3.lr.ph

for.body3.lr.ph:                                  ; preds = %for.cond1.preheader
  br label %for.body3

for.cond1.for.cond8.preheader_crit_edge:          ; preds = %for.body3
  br label %for.cond8.preheader

for.cond8.preheader:                              ; preds = %for.cond1.for.cond8.preheader_crit_edge, %for.cond1.preheader
  %indvars.iv.next62 = add nuw nsw i64 %indvars.iv61, 1
  %cmp918 = icmp slt i64 %indvars.iv.next62, %0
  br i1 %cmp918, label %for.body11.lr.ph, label %for.end18

for.body11.lr.ph:                                 ; preds = %for.cond8.preheader
  br label %for.body11

for.body3:                                        ; preds = %for.body3, %for.body3.lr.ph
  %indvars.iv46 = phi i64 [ %indvars.iv.next47, %for.body3 ], [ 0, %for.body3.lr.ph ]
  %1 = sub nsw i64 0, %indvars.iv46
  %2 = trunc i64 %1 to i32
  %rem = srem i32 %2, %n
  %conv = sitofp i32 %rem to double
  %conv4 = sitofp i32 %n to double
  %div = fdiv double %conv, %conv4
  %add = fadd double %div, 1.000000e+00
  %arrayidx6 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv61, i64 %indvars.iv46
  store double %add, double* %arrayidx6, align 8
  %indvars.iv.next47 = add nuw nsw i64 %indvars.iv46, 1
  %exitcond52 = icmp ne i64 %indvars.iv.next47, %indvars.iv59
  br i1 %exitcond52, label %for.body3, label %for.cond1.for.cond8.preheader_crit_edge

for.body11:                                       ; preds = %for.body11.lr.ph, %for.body11
  %indvars.iv55 = phi i64 [ %indvars.iv59, %for.body11.lr.ph ], [ %indvars.iv.next56, %for.body11 ]
  %arrayidx15 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv61, i64 %indvars.iv55
  store double 0.000000e+00, double* %arrayidx15, align 8
  %indvars.iv.next56 = add nuw nsw i64 %indvars.iv55, 1
  %wide.trip.count57 = zext i32 %n to i64
  %exitcond58 = icmp ne i64 %indvars.iv.next56, %wide.trip.count57
  br i1 %exitcond58, label %for.body11, label %for.cond8.for.end18_crit_edge

for.cond8.for.end18_crit_edge:                    ; preds = %for.body11
  br label %for.end18

for.end18:                                        ; preds = %for.cond8.for.end18_crit_edge, %for.cond8.preheader
  %arrayidx22 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv61, i64 %indvars.iv61
  store double 1.000000e+00, double* %arrayidx22, align 8
  %indvars.iv.next60 = add nuw nsw i64 %indvars.iv59, 1
  %wide.trip.count63 = zext i32 %n to i64
  %exitcond64 = icmp ne i64 %indvars.iv.next62, %wide.trip.count63
  br i1 %exitcond64, label %for.cond1.preheader, label %for.cond.for.end25_crit_edge

for.cond.for.end25_crit_edge:                     ; preds = %for.end18
  br label %for.end25

for.end25:                                        ; preds = %for.cond.for.end25_crit_edge, %entry.split
  %call = tail call i8* @polybench_alloc_data(i64 4000000, i32 8) #2
  %3 = bitcast i8* %call to [2000 x [2000 x double]]*
  %cmp2713 = icmp sgt i32 %n, 0
  br i1 %cmp2713, label %for.cond30.preheader.lr.ph, label %for.cond44.preheader

for.cond30.preheader.lr.ph:                       ; preds = %for.end25
  br label %for.cond30.preheader

for.cond30.preheader:                             ; preds = %for.cond30.preheader.lr.ph, %for.inc41
  %indvars.iv42 = phi i64 [ 0, %for.cond30.preheader.lr.ph ], [ %indvars.iv.next43, %for.inc41 ]
  %cmp3111 = icmp sgt i32 %n, 0
  br i1 %cmp3111, label %for.body33.lr.ph, label %for.inc41

for.body33.lr.ph:                                 ; preds = %for.cond30.preheader
  br label %for.body33

for.cond26.for.cond44.preheader_crit_edge:        ; preds = %for.inc41
  br label %for.cond44.preheader

for.cond44.preheader:                             ; preds = %for.cond26.for.cond44.preheader_crit_edge, %for.end25
  %cmp459 = icmp sgt i32 %n, 0
  br i1 %cmp459, label %for.cond48.preheader.lr.ph, label %for.cond78.preheader

for.cond48.preheader.lr.ph:                       ; preds = %for.cond44.preheader
  br label %for.cond48.preheader

for.body33:                                       ; preds = %for.body33.lr.ph, %for.body33
  %indvars.iv38 = phi i64 [ 0, %for.body33.lr.ph ], [ %indvars.iv.next39, %for.body33 ]
  %arrayidx37 = getelementptr inbounds [2000 x [2000 x double]], [2000 x [2000 x double]]* %3, i64 0, i64 %indvars.iv42, i64 %indvars.iv38
  store double 0.000000e+00, double* %arrayidx37, align 8
  %indvars.iv.next39 = add nuw nsw i64 %indvars.iv38, 1
  %wide.trip.count40 = zext i32 %n to i64
  %exitcond41 = icmp ne i64 %indvars.iv.next39, %wide.trip.count40
  br i1 %exitcond41, label %for.body33, label %for.cond30.for.inc41_crit_edge

for.cond30.for.inc41_crit_edge:                   ; preds = %for.body33
  br label %for.inc41

for.inc41:                                        ; preds = %for.cond30.for.inc41_crit_edge, %for.cond30.preheader
  %indvars.iv.next43 = add nuw nsw i64 %indvars.iv42, 1
  %wide.trip.count44 = zext i32 %n to i64
  %exitcond45 = icmp ne i64 %indvars.iv.next43, %wide.trip.count44
  br i1 %exitcond45, label %for.cond30.preheader, label %for.cond26.for.cond44.preheader_crit_edge

for.cond48.preheader:                             ; preds = %for.cond48.preheader.lr.ph, %for.inc75
  %indvars.iv34 = phi i64 [ 0, %for.cond48.preheader.lr.ph ], [ %indvars.iv.next35, %for.inc75 ]
  %cmp497 = icmp sgt i32 %n, 0
  br i1 %cmp497, label %for.cond52.preheader.lr.ph, label %for.inc75

for.cond52.preheader.lr.ph:                       ; preds = %for.cond48.preheader
  br label %for.cond52.preheader

for.cond44.for.cond78.preheader_crit_edge:        ; preds = %for.inc75
  br label %for.cond78.preheader

for.cond78.preheader:                             ; preds = %for.cond44.for.cond78.preheader_crit_edge, %for.cond44.preheader
  %cmp793 = icmp sgt i32 %n, 0
  br i1 %cmp793, label %for.cond82.preheader.lr.ph, label %for.end99

for.cond82.preheader.lr.ph:                       ; preds = %for.cond78.preheader
  br label %for.cond82.preheader

for.cond52.preheader:                             ; preds = %for.cond52.preheader.lr.ph, %for.inc72
  %indvars.iv30 = phi i64 [ 0, %for.cond52.preheader.lr.ph ], [ %indvars.iv.next31, %for.inc72 ]
  %cmp535 = icmp sgt i32 %n, 0
  br i1 %cmp535, label %for.body55.lr.ph, label %for.inc72

for.body55.lr.ph:                                 ; preds = %for.cond52.preheader
  br label %for.body55

for.body55:                                       ; preds = %for.body55.lr.ph, %for.body55
  %indvars.iv26 = phi i64 [ 0, %for.body55.lr.ph ], [ %indvars.iv.next27, %for.body55 ]
  %arrayidx59 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv30, i64 %indvars.iv34
  %4 = load double, double* %arrayidx59, align 8
  %arrayidx63 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv26, i64 %indvars.iv34
  %5 = load double, double* %arrayidx63, align 8
  %mul = fmul double %4, %5
  %arrayidx67 = getelementptr inbounds [2000 x [2000 x double]], [2000 x [2000 x double]]* %3, i64 0, i64 %indvars.iv30, i64 %indvars.iv26
  %6 = load double, double* %arrayidx67, align 8
  %add68 = fadd double %6, %mul
  store double %add68, double* %arrayidx67, align 8
  %indvars.iv.next27 = add nuw nsw i64 %indvars.iv26, 1
  %wide.trip.count28 = zext i32 %n to i64
  %exitcond29 = icmp ne i64 %indvars.iv.next27, %wide.trip.count28
  br i1 %exitcond29, label %for.body55, label %for.cond52.for.inc72_crit_edge

for.cond52.for.inc72_crit_edge:                   ; preds = %for.body55
  br label %for.inc72

for.inc72:                                        ; preds = %for.cond52.for.inc72_crit_edge, %for.cond52.preheader
  %indvars.iv.next31 = add nuw nsw i64 %indvars.iv30, 1
  %wide.trip.count32 = zext i32 %n to i64
  %exitcond33 = icmp ne i64 %indvars.iv.next31, %wide.trip.count32
  br i1 %exitcond33, label %for.cond52.preheader, label %for.cond48.for.inc75_crit_edge

for.cond48.for.inc75_crit_edge:                   ; preds = %for.inc72
  br label %for.inc75

for.inc75:                                        ; preds = %for.cond48.for.inc75_crit_edge, %for.cond48.preheader
  %indvars.iv.next35 = add nuw nsw i64 %indvars.iv34, 1
  %wide.trip.count36 = zext i32 %n to i64
  %exitcond37 = icmp ne i64 %indvars.iv.next35, %wide.trip.count36
  br i1 %exitcond37, label %for.cond48.preheader, label %for.cond44.for.cond78.preheader_crit_edge

for.cond82.preheader:                             ; preds = %for.cond82.preheader.lr.ph, %for.inc97
  %indvars.iv22 = phi i64 [ 0, %for.cond82.preheader.lr.ph ], [ %indvars.iv.next23, %for.inc97 ]
  %cmp831 = icmp sgt i32 %n, 0
  br i1 %cmp831, label %for.body85.lr.ph, label %for.inc97

for.body85.lr.ph:                                 ; preds = %for.cond82.preheader
  br label %for.body85

for.body85:                                       ; preds = %for.body85.lr.ph, %for.body85
  %indvars.iv = phi i64 [ 0, %for.body85.lr.ph ], [ %indvars.iv.next, %for.body85 ]
  %arrayidx89 = getelementptr inbounds [2000 x [2000 x double]], [2000 x [2000 x double]]* %3, i64 0, i64 %indvars.iv22, i64 %indvars.iv
  %7 = bitcast double* %arrayidx89 to i64*
  %8 = load i64, i64* %7, align 8
  %arrayidx93 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv22, i64 %indvars.iv
  %9 = bitcast double* %arrayidx93 to i64*
  store i64 %8, i64* %9, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %wide.trip.count = zext i32 %n to i64
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body85, label %for.cond82.for.inc97_crit_edge

for.cond82.for.inc97_crit_edge:                   ; preds = %for.body85
  br label %for.inc97

for.inc97:                                        ; preds = %for.cond82.for.inc97_crit_edge, %for.cond82.preheader
  %indvars.iv.next23 = add nuw nsw i64 %indvars.iv22, 1
  %wide.trip.count24 = zext i32 %n to i64
  %exitcond25 = icmp ne i64 %indvars.iv.next23, %wide.trip.count24
  br i1 %exitcond25, label %for.cond82.preheader, label %for.cond78.for.end99_crit_edge

for.cond78.for.end99_crit_edge:                   ; preds = %for.inc97
  br label %for.end99

for.end99:                                        ; preds = %for.cond78.for.end99_crit_edge, %for.cond78.preheader
  tail call void @free(i8* %call)
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define internal void @kernel_lu(i32 %n, [2000 x double]* %A) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %cmp9 = icmp sgt i32 %n, 0
  br i1 %cmp9, label %for.cond1.preheader.lr.ph, label %for.end56

for.cond1.preheader.lr.ph:                        ; preds = %entry.split
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.cond1.preheader.lr.ph, %for.inc54
  %indvars.iv31 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next32, %for.inc54 ]
  %cmp23 = icmp sgt i64 %indvars.iv31, 0
  br i1 %cmp23, label %for.cond4.preheader.lr.ph, label %for.cond28.preheader

for.cond4.preheader.lr.ph:                        ; preds = %for.cond1.preheader
  br label %for.cond4.preheader

for.cond1.for.cond28.preheader_crit_edge:         ; preds = %for.end
  br label %for.cond28.preheader

for.cond28.preheader:                             ; preds = %for.cond1.for.cond28.preheader_crit_edge, %for.cond1.preheader
  br i1 true, label %for.cond31.preheader.lr.ph, label %for.inc54

for.cond31.preheader.lr.ph:                       ; preds = %for.cond28.preheader
  br label %for.cond31.preheader

for.cond4.preheader:                              ; preds = %for.cond4.preheader.lr.ph, %for.end
  %indvars.iv14 = phi i64 [ 0, %for.cond4.preheader.lr.ph ], [ %indvars.iv.next15, %for.end ]
  %cmp51 = icmp sgt i64 %indvars.iv14, 0
  br i1 %cmp51, label %for.body6.lr.ph, label %for.end

for.body6.lr.ph:                                  ; preds = %for.cond4.preheader
  br label %for.body6

for.body6:                                        ; preds = %for.body6.lr.ph, %for.body6
  %indvars.iv = phi i64 [ 0, %for.body6.lr.ph ], [ %indvars.iv.next, %for.body6 ]
  %arrayidx8 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv31, i64 %indvars.iv
  %0 = load double, double* %arrayidx8, align 8
  %arrayidx12 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv, i64 %indvars.iv14
  %1 = load double, double* %arrayidx12, align 8
  %mul = fmul double %0, %1
  %arrayidx16 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv31, i64 %indvars.iv14
  %2 = load double, double* %arrayidx16, align 8
  %sub = fsub double %2, %mul
  store double %sub, double* %arrayidx16, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, %indvars.iv14
  br i1 %exitcond, label %for.body6, label %for.cond4.for.end_crit_edge

for.cond4.for.end_crit_edge:                      ; preds = %for.body6
  br label %for.end

for.end:                                          ; preds = %for.cond4.for.end_crit_edge, %for.cond4.preheader
  %arrayidx20 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv14, i64 %indvars.iv14
  %3 = load double, double* %arrayidx20, align 8
  %arrayidx24 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv31, i64 %indvars.iv14
  %4 = load double, double* %arrayidx24, align 8
  %div = fdiv double %4, %3
  store double %div, double* %arrayidx24, align 8
  %indvars.iv.next15 = add nuw nsw i64 %indvars.iv14, 1
  %exitcond19 = icmp ne i64 %indvars.iv.next15, %indvars.iv31
  br i1 %exitcond19, label %for.cond4.preheader, label %for.cond1.for.cond28.preheader_crit_edge

for.cond31.preheader:                             ; preds = %for.cond31.preheader.lr.ph, %for.inc51
  %indvars.iv27 = phi i64 [ %indvars.iv31, %for.cond31.preheader.lr.ph ], [ %indvars.iv.next28, %for.inc51 ]
  %cmp325 = icmp sgt i64 %indvars.iv31, 0
  br i1 %cmp325, label %for.body33.lr.ph, label %for.inc51

for.body33.lr.ph:                                 ; preds = %for.cond31.preheader
  br label %for.body33

for.body33:                                       ; preds = %for.body33.lr.ph, %for.body33
  %indvars.iv20 = phi i64 [ 0, %for.body33.lr.ph ], [ %indvars.iv.next21, %for.body33 ]
  %arrayidx37 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv31, i64 %indvars.iv20
  %5 = load double, double* %arrayidx37, align 8
  %arrayidx41 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv20, i64 %indvars.iv27
  %6 = load double, double* %arrayidx41, align 8
  %mul42 = fmul double %5, %6
  %arrayidx46 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv31, i64 %indvars.iv27
  %7 = load double, double* %arrayidx46, align 8
  %sub47 = fsub double %7, %mul42
  store double %sub47, double* %arrayidx46, align 8
  %indvars.iv.next21 = add nuw nsw i64 %indvars.iv20, 1
  %exitcond24 = icmp ne i64 %indvars.iv.next21, %indvars.iv31
  br i1 %exitcond24, label %for.body33, label %for.cond31.for.inc51_crit_edge

for.cond31.for.inc51_crit_edge:                   ; preds = %for.body33
  br label %for.inc51

for.inc51:                                        ; preds = %for.cond31.for.inc51_crit_edge, %for.cond31.preheader
  %indvars.iv.next28 = add nuw nsw i64 %indvars.iv27, 1
  %wide.trip.count29 = zext i32 %n to i64
  %exitcond30 = icmp ne i64 %indvars.iv.next28, %wide.trip.count29
  br i1 %exitcond30, label %for.cond31.preheader, label %for.cond28.for.inc54_crit_edge

for.cond28.for.inc54_crit_edge:                   ; preds = %for.inc51
  br label %for.inc54

for.inc54:                                        ; preds = %for.cond28.for.inc54_crit_edge, %for.cond28.preheader
  %indvars.iv.next32 = add nuw nsw i64 %indvars.iv31, 1
  %wide.trip.count33 = zext i32 %n to i64
  %exitcond34 = icmp ne i64 %indvars.iv.next32, %wide.trip.count33
  br i1 %exitcond34, label %for.cond1.preheader, label %for.cond.for.end56_crit_edge

for.cond.for.end56_crit_edge:                     ; preds = %for.inc54
  br label %for.end56

for.end56:                                        ; preds = %for.cond.for.end56_crit_edge, %entry.split
  ret void
}

declare i32 @strcmp(i8*, i8*) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal void @print_array(i32 %n, [2000 x double]* %A) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %1 = tail call i64 @fwrite(i8* getelementptr inbounds ([23 x i8], [23 x i8]* @.str.1, i64 0, i64 0), i64 22, i64 1, %struct.__sFILE* %0)
  %2 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %call1 = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %2, i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.2, i64 0, i64 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.3, i64 0, i64 0)) #2
  %cmp4 = icmp sgt i32 %n, 0
  br i1 %cmp4, label %for.cond2.preheader.lr.ph, label %for.end12

for.cond2.preheader.lr.ph:                        ; preds = %entry.split
  %3 = sext i32 %n to i64
  br label %for.cond2.preheader

for.cond2.preheader:                              ; preds = %for.cond2.preheader.lr.ph, %for.inc10
  %indvars.iv8 = phi i64 [ 0, %for.cond2.preheader.lr.ph ], [ %indvars.iv.next9, %for.inc10 ]
  %cmp31 = icmp sgt i32 %n, 0
  br i1 %cmp31, label %for.body4.lr.ph, label %for.inc10

for.body4.lr.ph:                                  ; preds = %for.cond2.preheader
  br label %for.body4

for.body4:                                        ; preds = %for.body4.lr.ph, %if.end
  %indvars.iv = phi i64 [ 0, %for.body4.lr.ph ], [ %indvars.iv.next, %if.end ]
  %4 = mul nsw i64 %indvars.iv8, %3
  %5 = add nsw i64 %indvars.iv, %4
  %6 = trunc i64 %5 to i32
  %rem = srem i32 %6, 20
  %cmp5 = icmp eq i32 %rem, 0
  br i1 %cmp5, label %if.then, label %if.end

if.then:                                          ; preds = %for.body4
  %7 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %fputc = tail call i32 @fputc(i32 10, %struct.__sFILE* %7)
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body4
  %8 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %arrayidx8 = getelementptr inbounds [2000 x double], [2000 x double]* %A, i64 %indvars.iv8, i64 %indvars.iv
  %9 = load double, double* %arrayidx8, align 8
  %call9 = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %8, i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.5, i64 0, i64 0), double %9) #2
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %wide.trip.count = zext i32 %n to i64
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body4, label %for.cond2.for.inc10_crit_edge

for.cond2.for.inc10_crit_edge:                    ; preds = %if.end
  br label %for.inc10

for.inc10:                                        ; preds = %for.cond2.for.inc10_crit_edge, %for.cond2.preheader
  %indvars.iv.next9 = add nuw nsw i64 %indvars.iv8, 1
  %wide.trip.count11 = zext i32 %n to i64
  %exitcond12 = icmp ne i64 %indvars.iv.next9, %wide.trip.count11
  br i1 %exitcond12, label %for.cond2.preheader, label %for.cond.for.end12_crit_edge

for.cond.for.end12_crit_edge:                     ; preds = %for.inc10
  br label %for.end12

for.end12:                                        ; preds = %for.cond.for.end12_crit_edge, %entry.split
  %10 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %call13 = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %10, i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.6, i64 0, i64 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.3, i64 0, i64 0)) #2
  %11 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %12 = tail call i64 @fwrite(i8* getelementptr inbounds ([23 x i8], [23 x i8]* @.str.7, i64 0, i64 0), i64 22, i64 1, %struct.__sFILE* %11)
  ret void
}

declare void @free(i8*) #1

declare i32 @fprintf(%struct.__sFILE*, i8*, ...) #1

; Function Attrs: nounwind
declare i64 @fwrite(i8* nocapture, i64, i64, %struct.__sFILE* nocapture) #2

; Function Attrs: nounwind
declare i32 @fputc(i32, %struct.__sFILE* nocapture) #2

attributes #0 = { noinline nounwind ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"PIC Level", i32 2}
!1 = !{!"clang version 5.0.0 (http://llvm.org/git/clang.git 88423634c5b7688be89586484a68e5a1167b1280) (http://llvm.org/git/llvm.git 405d07a3a61aff7681568173e5e44c09fc7ff945)"}

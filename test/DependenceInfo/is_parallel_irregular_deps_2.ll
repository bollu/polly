; Test file taken from Polybench:
; polybench-c-4.2.1-beta/linear-algebra/kernels/2mm/2mm.c

; This contains dependences that contain isl_maps which do not share the same
; underlying space. We check that this is fixed by Dependences::isParallel().

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
@.str.3 = private unnamed_addr constant [2 x i8] c"D\00", align 1
@.str.4 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.5 = private unnamed_addr constant [8 x i8] c"%0.2lf \00", align 1
@.str.6 = private unnamed_addr constant [17 x i8] c"\0Aend   dump: %s\0A\00", align 1
@.str.7 = private unnamed_addr constant [23 x i8] c"==END   DUMP_ARRAYS==\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
entry:
  %alpha = alloca double, align 8
  %beta = alloca double, align 8
  br label %entry.split

entry.split:                                      ; preds = %entry
  %call = tail call i8* @polybench_alloc_data(i64 720000, i32 8) #2
  %call2 = tail call i8* @polybench_alloc_data(i64 880000, i32 8) #2
  %call4 = tail call i8* @polybench_alloc_data(i64 990000, i32 8) #2
  %call6 = tail call i8* @polybench_alloc_data(i64 1080000, i32 8) #2
  %call8 = tail call i8* @polybench_alloc_data(i64 960000, i32 8) #2
  %arraydecay = bitcast i8* %call2 to [1100 x double]*
  %arraydecay9 = bitcast i8* %call4 to [900 x double]*
  %arraydecay10 = bitcast i8* %call6 to [1200 x double]*
  %arraydecay11 = bitcast i8* %call8 to [1200 x double]*
  call void @init_array(i32 800, i32 900, i32 1100, i32 1200, double* nonnull %alpha, double* nonnull %beta, [1100 x double]* %arraydecay, [900 x double]* %arraydecay9, [1200 x double]* %arraydecay10, [1200 x double]* %arraydecay11)
  %0 = load double, double* %alpha, align 8
  %1 = load double, double* %beta, align 8
  %arraydecay12 = bitcast i8* %call to [900 x double]*
  %arraydecay13 = bitcast i8* %call2 to [1100 x double]*
  %arraydecay14 = bitcast i8* %call4 to [900 x double]*
  %arraydecay15 = bitcast i8* %call6 to [1200 x double]*
  %arraydecay16 = bitcast i8* %call8 to [1200 x double]*
  call void @kernel_2mm(i32 800, i32 900, i32 1100, i32 1200, double %0, double %1, [900 x double]* %arraydecay12, [1100 x double]* %arraydecay13, [900 x double]* %arraydecay14, [1200 x double]* %arraydecay15, [1200 x double]* %arraydecay16)
  %cmp = icmp sgt i32 %argc, 42
  br i1 %cmp, label %land.lhs.true, label %if.end

land.lhs.true:                                    ; preds = %entry.split
  %2 = load i8*, i8** %argv, align 8
  %strcmpload = load i8, i8* %2, align 1
  %tobool = icmp eq i8 %strcmpload, 0
  br i1 %tobool, label %if.then, label %if.end

if.then:                                          ; preds = %land.lhs.true
  %arraydecay18 = bitcast i8* %call8 to [1200 x double]*
  call void @print_array(i32 800, i32 1200, [1200 x double]* %arraydecay18)
  br label %if.end

if.end:                                           ; preds = %land.lhs.true, %if.then, %entry.split
  call void @free(i8* %call)
  call void @free(i8* %call2)
  call void @free(i8* %call4)
  call void @free(i8* %call6)
  call void @free(i8* %call8)
  ret i32 0
}

declare i8* @polybench_alloc_data(i64, i32) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal void @init_array(i32 %ni, i32 %nj, i32 %nk, i32 %nl, double* %alpha, double* %beta, [1100 x double]* %A, [900 x double]* %B, [1200 x double]* %C, [1200 x double]* %D) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  store double 1.500000e+00, double* %alpha, align 8
  store double 1.200000e+00, double* %beta, align 8
  %cmp18 = icmp sgt i32 %ni, 0
  br i1 %cmp18, label %for.cond1.preheader.lr.ph, label %for.cond10.preheader

for.cond1.preheader.lr.ph:                        ; preds = %entry.split
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.cond1.preheader.lr.ph, %for.inc7
  %indvars.iv53 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next54, %for.inc7 ]
  %cmp216 = icmp sgt i32 %nk, 0
  br i1 %cmp216, label %for.body3.lr.ph, label %for.inc7

for.body3.lr.ph:                                  ; preds = %for.cond1.preheader
  br label %for.body3

for.cond.for.cond10.preheader_crit_edge:          ; preds = %for.inc7
  br label %for.cond10.preheader

for.cond10.preheader:                             ; preds = %for.cond.for.cond10.preheader_crit_edge, %entry.split
  %cmp1113 = icmp sgt i32 %nk, 0
  br i1 %cmp1113, label %for.cond14.preheader.lr.ph, label %for.cond34.preheader

for.cond14.preheader.lr.ph:                       ; preds = %for.cond10.preheader
  br label %for.cond14.preheader

for.body3:                                        ; preds = %for.body3.lr.ph, %for.body3
  %indvars.iv47 = phi i64 [ 0, %for.body3.lr.ph ], [ %indvars.iv.next48, %for.body3 ]
  %0 = mul nuw nsw i64 %indvars.iv47, %indvars.iv53
  %1 = add nuw nsw i64 %0, 1
  %2 = trunc i64 %1 to i32
  %rem = srem i32 %2, %ni
  %conv = sitofp i32 %rem to double
  %conv4 = sitofp i32 %ni to double
  %div = fdiv double %conv, %conv4
  %arrayidx6 = getelementptr inbounds [1100 x double], [1100 x double]* %A, i64 %indvars.iv53, i64 %indvars.iv47
  store double %div, double* %arrayidx6, align 8
  %indvars.iv.next48 = add nuw nsw i64 %indvars.iv47, 1
  %wide.trip.count51 = zext i32 %nk to i64
  %exitcond52 = icmp ne i64 %indvars.iv.next48, %wide.trip.count51
  br i1 %exitcond52, label %for.body3, label %for.cond1.for.inc7_crit_edge

for.cond1.for.inc7_crit_edge:                     ; preds = %for.body3
  br label %for.inc7

for.inc7:                                         ; preds = %for.cond1.for.inc7_crit_edge, %for.cond1.preheader
  %indvars.iv.next54 = add nuw nsw i64 %indvars.iv53, 1
  %wide.trip.count55 = zext i32 %ni to i64
  %exitcond56 = icmp ne i64 %indvars.iv.next54, %wide.trip.count55
  br i1 %exitcond56, label %for.cond1.preheader, label %for.cond.for.cond10.preheader_crit_edge

for.cond14.preheader:                             ; preds = %for.cond14.preheader.lr.ph, %for.inc31
  %indvars.iv43 = phi i64 [ 0, %for.cond14.preheader.lr.ph ], [ %indvars.iv.next44, %for.inc31 ]
  %cmp1511 = icmp sgt i32 %nj, 0
  br i1 %cmp1511, label %for.body17.lr.ph, label %for.inc31

for.body17.lr.ph:                                 ; preds = %for.cond14.preheader
  br label %for.body17

for.cond10.for.cond34.preheader_crit_edge:        ; preds = %for.inc31
  br label %for.cond34.preheader

for.cond34.preheader:                             ; preds = %for.cond10.for.cond34.preheader_crit_edge, %for.cond10.preheader
  %cmp358 = icmp sgt i32 %nj, 0
  br i1 %cmp358, label %for.cond38.preheader.lr.ph, label %for.cond59.preheader

for.cond38.preheader.lr.ph:                       ; preds = %for.cond34.preheader
  br label %for.cond38.preheader

for.body17:                                       ; preds = %for.body17.lr.ph, %for.body17
  %indvars.iv38 = phi i64 [ 0, %for.body17.lr.ph ], [ %indvars.iv.next39, %for.body17 ]
  %indvars.iv.next39 = add nuw nsw i64 %indvars.iv38, 1
  %3 = mul nuw nsw i64 %indvars.iv.next39, %indvars.iv43
  %4 = trunc i64 %3 to i32
  %rem20 = srem i32 %4, %nj
  %conv21 = sitofp i32 %rem20 to double
  %conv22 = sitofp i32 %nj to double
  %div23 = fdiv double %conv21, %conv22
  %arrayidx27 = getelementptr inbounds [900 x double], [900 x double]* %B, i64 %indvars.iv43, i64 %indvars.iv38
  store double %div23, double* %arrayidx27, align 8
  %wide.trip.count41 = zext i32 %nj to i64
  %exitcond42 = icmp ne i64 %indvars.iv.next39, %wide.trip.count41
  br i1 %exitcond42, label %for.body17, label %for.cond14.for.inc31_crit_edge

for.cond14.for.inc31_crit_edge:                   ; preds = %for.body17
  br label %for.inc31

for.inc31:                                        ; preds = %for.cond14.for.inc31_crit_edge, %for.cond14.preheader
  %indvars.iv.next44 = add nuw nsw i64 %indvars.iv43, 1
  %wide.trip.count45 = zext i32 %nk to i64
  %exitcond46 = icmp ne i64 %indvars.iv.next44, %wide.trip.count45
  br i1 %exitcond46, label %for.cond14.preheader, label %for.cond10.for.cond34.preheader_crit_edge

for.cond38.preheader:                             ; preds = %for.cond38.preheader.lr.ph, %for.inc56
  %indvars.iv34 = phi i64 [ 0, %for.cond38.preheader.lr.ph ], [ %indvars.iv.next35, %for.inc56 ]
  %cmp396 = icmp sgt i32 %nl, 0
  br i1 %cmp396, label %for.body41.lr.ph, label %for.inc56

for.body41.lr.ph:                                 ; preds = %for.cond38.preheader
  br label %for.body41

for.cond34.for.cond59.preheader_crit_edge:        ; preds = %for.inc56
  br label %for.cond59.preheader

for.cond59.preheader:                             ; preds = %for.cond34.for.cond59.preheader_crit_edge, %for.cond34.preheader
  %cmp603 = icmp sgt i32 %ni, 0
  br i1 %cmp603, label %for.cond63.preheader.lr.ph, label %for.end82

for.cond63.preheader.lr.ph:                       ; preds = %for.cond59.preheader
  br label %for.cond63.preheader

for.body41:                                       ; preds = %for.body41.lr.ph, %for.body41
  %indvars.iv27 = phi i64 [ 0, %for.body41.lr.ph ], [ %indvars.iv.next28, %for.body41 ]
  %5 = add nuw nsw i64 %indvars.iv27, 3
  %6 = mul nuw nsw i64 %5, %indvars.iv34
  %7 = add nuw nsw i64 %6, 1
  %8 = trunc i64 %7 to i32
  %rem45 = srem i32 %8, %nl
  %conv46 = sitofp i32 %rem45 to double
  %conv47 = sitofp i32 %nl to double
  %div48 = fdiv double %conv46, %conv47
  %arrayidx52 = getelementptr inbounds [1200 x double], [1200 x double]* %C, i64 %indvars.iv34, i64 %indvars.iv27
  store double %div48, double* %arrayidx52, align 8
  %indvars.iv.next28 = add nuw nsw i64 %indvars.iv27, 1
  %wide.trip.count32 = zext i32 %nl to i64
  %exitcond33 = icmp ne i64 %indvars.iv.next28, %wide.trip.count32
  br i1 %exitcond33, label %for.body41, label %for.cond38.for.inc56_crit_edge

for.cond38.for.inc56_crit_edge:                   ; preds = %for.body41
  br label %for.inc56

for.inc56:                                        ; preds = %for.cond38.for.inc56_crit_edge, %for.cond38.preheader
  %indvars.iv.next35 = add nuw nsw i64 %indvars.iv34, 1
  %wide.trip.count36 = zext i32 %nj to i64
  %exitcond37 = icmp ne i64 %indvars.iv.next35, %wide.trip.count36
  br i1 %exitcond37, label %for.cond38.preheader, label %for.cond34.for.cond59.preheader_crit_edge

for.cond63.preheader:                             ; preds = %for.cond63.preheader.lr.ph, %for.inc80
  %indvars.iv23 = phi i64 [ 0, %for.cond63.preheader.lr.ph ], [ %indvars.iv.next24, %for.inc80 ]
  %cmp641 = icmp sgt i32 %nl, 0
  br i1 %cmp641, label %for.body66.lr.ph, label %for.inc80

for.body66.lr.ph:                                 ; preds = %for.cond63.preheader
  br label %for.body66

for.body66:                                       ; preds = %for.body66.lr.ph, %for.body66
  %indvars.iv = phi i64 [ 0, %for.body66.lr.ph ], [ %indvars.iv.next, %for.body66 ]
  %9 = add nuw nsw i64 %indvars.iv, 2
  %10 = mul nuw nsw i64 %9, %indvars.iv23
  %11 = trunc i64 %10 to i32
  %rem69 = srem i32 %11, %nk
  %conv70 = sitofp i32 %rem69 to double
  %conv71 = sitofp i32 %nk to double
  %div72 = fdiv double %conv70, %conv71
  %arrayidx76 = getelementptr inbounds [1200 x double], [1200 x double]* %D, i64 %indvars.iv23, i64 %indvars.iv
  store double %div72, double* %arrayidx76, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %wide.trip.count = zext i32 %nl to i64
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body66, label %for.cond63.for.inc80_crit_edge

for.cond63.for.inc80_crit_edge:                   ; preds = %for.body66
  br label %for.inc80

for.inc80:                                        ; preds = %for.cond63.for.inc80_crit_edge, %for.cond63.preheader
  %indvars.iv.next24 = add nuw nsw i64 %indvars.iv23, 1
  %wide.trip.count25 = zext i32 %ni to i64
  %exitcond26 = icmp ne i64 %indvars.iv.next24, %wide.trip.count25
  br i1 %exitcond26, label %for.cond63.preheader, label %for.cond59.for.end82_crit_edge

for.cond59.for.end82_crit_edge:                   ; preds = %for.inc80
  br label %for.end82

for.end82:                                        ; preds = %for.cond59.for.end82_crit_edge, %for.cond59.preheader
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define internal void @kernel_2mm(i32 %ni, i32 %nj, i32 %nk, i32 %nl, double %alpha, double %beta, [900 x double]* %tmp, [1100 x double]* %A, [900 x double]* %B, [1200 x double]* %C, [1200 x double]* %D) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %cmp11 = icmp sgt i32 %ni, 0
  br i1 %cmp11, label %for.cond4.preheader.lr.ph, label %for.cond31.preheader

for.cond4.preheader.lr.ph:                        ; preds = %entry.split
  br label %for.cond4.preheader

for.cond4.preheader:                              ; preds = %for.cond4.preheader.lr.ph, %for.inc28
  %indvars.iv29 = phi i64 [ 0, %for.cond4.preheader.lr.ph ], [ %indvars.iv.next30, %for.inc28 ]
  %cmp59 = icmp sgt i32 %nj, 0
  br i1 %cmp59, label %for.body6.lr.ph, label %for.inc28

for.body6.lr.ph:                                  ; preds = %for.cond4.preheader
  br label %for.body6

for.cond.for.cond31.preheader_crit_edge:          ; preds = %for.inc28
  br label %for.cond31.preheader

for.cond31.preheader:                             ; preds = %for.cond.for.cond31.preheader_crit_edge, %entry.split
  %cmp325 = icmp sgt i32 %ni, 0
  br i1 %cmp325, label %for.cond34.preheader.lr.ph, label %for.end67

for.cond34.preheader.lr.ph:                       ; preds = %for.cond31.preheader
  br label %for.cond34.preheader

for.body6:                                        ; preds = %for.body6.lr.ph, %for.inc25
  %indvars.iv25 = phi i64 [ 0, %for.body6.lr.ph ], [ %indvars.iv.next26, %for.inc25 ]
  %arrayidx8 = getelementptr inbounds [900 x double], [900 x double]* %tmp, i64 %indvars.iv29, i64 %indvars.iv25
  store double 0.000000e+00, double* %arrayidx8, align 8
  %cmp107 = icmp sgt i32 %nk, 0
  br i1 %cmp107, label %for.body11.lr.ph, label %for.inc25

for.body11.lr.ph:                                 ; preds = %for.body6
  br label %for.body11

for.body11:                                       ; preds = %for.body11.lr.ph, %for.body11
  %indvars.iv21 = phi i64 [ 0, %for.body11.lr.ph ], [ %indvars.iv.next22, %for.body11 ]
  %arrayidx15 = getelementptr inbounds [1100 x double], [1100 x double]* %A, i64 %indvars.iv29, i64 %indvars.iv21
  %0 = load double, double* %arrayidx15, align 8
  %mul = fmul double %0, %alpha
  %arrayidx19 = getelementptr inbounds [900 x double], [900 x double]* %B, i64 %indvars.iv21, i64 %indvars.iv25
  %1 = load double, double* %arrayidx19, align 8
  %mul20 = fmul double %mul, %1
  %arrayidx24 = getelementptr inbounds [900 x double], [900 x double]* %tmp, i64 %indvars.iv29, i64 %indvars.iv25
  %2 = load double, double* %arrayidx24, align 8
  %add = fadd double %2, %mul20
  store double %add, double* %arrayidx24, align 8
  %indvars.iv.next22 = add nuw nsw i64 %indvars.iv21, 1
  %wide.trip.count23 = zext i32 %nk to i64
  %exitcond24 = icmp ne i64 %indvars.iv.next22, %wide.trip.count23
  br i1 %exitcond24, label %for.body11, label %for.cond9.for.inc25_crit_edge

for.cond9.for.inc25_crit_edge:                    ; preds = %for.body11
  br label %for.inc25

for.inc25:                                        ; preds = %for.cond9.for.inc25_crit_edge, %for.body6
  %indvars.iv.next26 = add nuw nsw i64 %indvars.iv25, 1
  %wide.trip.count27 = zext i32 %nj to i64
  %exitcond28 = icmp ne i64 %indvars.iv.next26, %wide.trip.count27
  br i1 %exitcond28, label %for.body6, label %for.cond4.for.inc28_crit_edge

for.cond4.for.inc28_crit_edge:                    ; preds = %for.inc25
  br label %for.inc28

for.inc28:                                        ; preds = %for.cond4.for.inc28_crit_edge, %for.cond4.preheader
  %indvars.iv.next30 = add nuw nsw i64 %indvars.iv29, 1
  %wide.trip.count31 = zext i32 %ni to i64
  %exitcond32 = icmp ne i64 %indvars.iv.next30, %wide.trip.count31
  br i1 %exitcond32, label %for.cond4.preheader, label %for.cond.for.cond31.preheader_crit_edge

for.cond34.preheader:                             ; preds = %for.cond34.preheader.lr.ph, %for.inc65
  %indvars.iv17 = phi i64 [ 0, %for.cond34.preheader.lr.ph ], [ %indvars.iv.next18, %for.inc65 ]
  %cmp353 = icmp sgt i32 %nl, 0
  br i1 %cmp353, label %for.body36.lr.ph, label %for.inc65

for.body36.lr.ph:                                 ; preds = %for.cond34.preheader
  br label %for.body36

for.body36:                                       ; preds = %for.body36.lr.ph, %for.inc62
  %indvars.iv13 = phi i64 [ 0, %for.body36.lr.ph ], [ %indvars.iv.next14, %for.inc62 ]
  %arrayidx40 = getelementptr inbounds [1200 x double], [1200 x double]* %D, i64 %indvars.iv17, i64 %indvars.iv13
  %3 = load double, double* %arrayidx40, align 8
  %mul41 = fmul double %3, %beta
  store double %mul41, double* %arrayidx40, align 8
  %cmp431 = icmp sgt i32 %nj, 0
  br i1 %cmp431, label %for.body44.lr.ph, label %for.inc62

for.body44.lr.ph:                                 ; preds = %for.body36
  br label %for.body44

for.body44:                                       ; preds = %for.body44.lr.ph, %for.body44
  %indvars.iv = phi i64 [ 0, %for.body44.lr.ph ], [ %indvars.iv.next, %for.body44 ]
  %arrayidx48 = getelementptr inbounds [900 x double], [900 x double]* %tmp, i64 %indvars.iv17, i64 %indvars.iv
  %4 = load double, double* %arrayidx48, align 8
  %arrayidx52 = getelementptr inbounds [1200 x double], [1200 x double]* %C, i64 %indvars.iv, i64 %indvars.iv13
  %5 = load double, double* %arrayidx52, align 8
  %mul53 = fmul double %4, %5
  %arrayidx57 = getelementptr inbounds [1200 x double], [1200 x double]* %D, i64 %indvars.iv17, i64 %indvars.iv13
  %6 = load double, double* %arrayidx57, align 8
  %add58 = fadd double %6, %mul53
  store double %add58, double* %arrayidx57, align 8
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %wide.trip.count = zext i32 %nj to i64
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body44, label %for.cond42.for.inc62_crit_edge

for.cond42.for.inc62_crit_edge:                   ; preds = %for.body44
  br label %for.inc62

for.inc62:                                        ; preds = %for.cond42.for.inc62_crit_edge, %for.body36
  %indvars.iv.next14 = add nuw nsw i64 %indvars.iv13, 1
  %wide.trip.count15 = zext i32 %nl to i64
  %exitcond16 = icmp ne i64 %indvars.iv.next14, %wide.trip.count15
  br i1 %exitcond16, label %for.body36, label %for.cond34.for.inc65_crit_edge

for.cond34.for.inc65_crit_edge:                   ; preds = %for.inc62
  br label %for.inc65

for.inc65:                                        ; preds = %for.cond34.for.inc65_crit_edge, %for.cond34.preheader
  %indvars.iv.next18 = add nuw nsw i64 %indvars.iv17, 1
  %wide.trip.count19 = zext i32 %ni to i64
  %exitcond20 = icmp ne i64 %indvars.iv.next18, %wide.trip.count19
  br i1 %exitcond20, label %for.cond34.preheader, label %for.cond31.for.end67_crit_edge

for.cond31.for.end67_crit_edge:                   ; preds = %for.inc65
  br label %for.end67

for.end67:                                        ; preds = %for.cond31.for.end67_crit_edge, %for.cond31.preheader
  ret void
}

declare i32 @strcmp(i8*, i8*) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal void @print_array(i32 %ni, i32 %nl, [1200 x double]* %D) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %0 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %1 = tail call i64 @fwrite(i8* getelementptr inbounds ([23 x i8], [23 x i8]* @.str.1, i64 0, i64 0), i64 22, i64 1, %struct.__sFILE* %0)
  %2 = load %struct.__sFILE*, %struct.__sFILE** @__stderrp, align 8
  %call1 = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %2, i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str.2, i64 0, i64 0), i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.3, i64 0, i64 0)) #2
  %cmp4 = icmp sgt i32 %ni, 0
  br i1 %cmp4, label %for.cond2.preheader.lr.ph, label %for.end12

for.cond2.preheader.lr.ph:                        ; preds = %entry.split
  %3 = sext i32 %ni to i64
  br label %for.cond2.preheader

for.cond2.preheader:                              ; preds = %for.cond2.preheader.lr.ph, %for.inc10
  %indvars.iv8 = phi i64 [ 0, %for.cond2.preheader.lr.ph ], [ %indvars.iv.next9, %for.inc10 ]
  %cmp31 = icmp sgt i32 %nl, 0
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
  %arrayidx8 = getelementptr inbounds [1200 x double], [1200 x double]* %D, i64 %indvars.iv8, i64 %indvars.iv
  %9 = load double, double* %arrayidx8, align 8
  %call9 = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %8, i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.5, i64 0, i64 0), double %9) #2
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %wide.trip.count = zext i32 %nl to i64
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body4, label %for.cond2.for.inc10_crit_edge

for.cond2.for.inc10_crit_edge:                    ; preds = %if.end
  br label %for.inc10

for.inc10:                                        ; preds = %for.cond2.for.inc10_crit_edge, %for.cond2.preheader
  %indvars.iv.next9 = add nuw nsw i64 %indvars.iv8, 1
  %wide.trip.count11 = zext i32 %ni to i64
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
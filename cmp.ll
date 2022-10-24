@.str9 = private unnamed_addr constant [10 x i8] c"%d != %d\0A\00"
@.str8 = private unnamed_addr constant [17 x i8] c"\0Aa = %d, b = %d\0A\00"
@.str7 = private unnamed_addr constant [10 x i8] c"%d <= %d\0A\00"
@.str6 = private unnamed_addr constant [10 x i8] c"%d >= %d\0A\00"
@.str5 = private unnamed_addr constant [17 x i8] c"\0Aa = %d, b = %d\0A\00"
@.str4 = private unnamed_addr constant [10 x i8] c"%d == %d\0A\00"
@.str3 = private unnamed_addr constant [9 x i8] c"%d < %d\0A\00"
@.str2 = private unnamed_addr constant [9 x i8] c"%d > %d\0A\00"
@.str1 = private unnamed_addr constant [16 x i8] c"a = %d, b = %d\0A\00"
; === prologue ====
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i32, i1)
declare dso_local i32 @__isoc99_scanf(i8*, ...)
declare dso_local i32 @printf(i8*, ...)
declare dso_local i64 @strlen(i8*)
declare dso_local i32 @open(i8*, i32, ...)
declare dso_local i32 @read(...)
declare dso_local i32 @write(...)
declare dso_local i32 @close(...)
define dso_local i32 @main(){
	 %1 = alloca i32
	 store i32 20, i32* %1
	 %2 = alloca i32
	 store i32 20, i32* %2
	 %3 = load i32, i32* %1
	 %4 = load i32, i32* %2
	 %5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([16 x i8], [16 x i8]* @.str1, i32 0, i32 0), i32 %3, i32 %4)
	 %6 = load i32, i32* %1
	 %7 = load i32, i32* %2
	 %8 = icmp sgt i32 %6, %7
	 br i1 %8, label %L1, label %L2
L1:
	 %9 = load i32, i32* %1
	 %10 = load i32, i32* %2
	 %11 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str2, i32 0, i32 0), i32 %9, i32 %10)
	 br label %L3
L2:
	 %12 = load i32, i32* %1
	 %13 = load i32, i32* %2
	 %14 = icmp slt i32 %12, %13
	 br i1 %14, label %L4, label %L5
L4:
	 %15 = load i32, i32* %1
	 %16 = load i32, i32* %2
	 %17 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str3, i32 0, i32 0), i32 %15, i32 %16)
	 br label %L3
L5:
	 %18 = load i32, i32* %1
	 %19 = load i32, i32* %2
	 %20 = icmp eq i32 %18, %19
	 br i1 %20, label %L7, label %L8
L7:
	 %21 = load i32, i32* %2
	 %22 = load i32, i32* %1
	 %23 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str4, i32 0, i32 0), i32 %21, i32 %22)
	 br label %L6
L8:
	 br label %L6
L3:
	 br label %L6
L6:
	 store i32 30, i32* %1
	 store i32 30, i32* %2
	 %24 = load i32, i32* %1
	 %25 = load i32, i32* %2
	 %26 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str5, i32 0, i32 0), i32 %24, i32 %25)
	 %27 = load i32, i32* %1
	 %28 = load i32, i32* %2
	 %29 = icmp sge i32 %27, %28
	 br i1 %29, label %L9, label %L10
L9:
	 %30 = load i32, i32* %1
	 %31 = load i32, i32* %2
	 %32 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str6, i32 0, i32 0), i32 %30, i32 %31)
	 br label %L11
L10:
	 %33 = load i32, i32* %1
	 %34 = load i32, i32* %2
	 %35 = icmp sle i32 %33, %34
	 br i1 %35, label %L12, label %L13
L12:
	 %36 = load i32, i32* %1
	 %37 = load i32, i32* %2
	 %38 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str7, i32 0, i32 0), i32 %36, i32 %37)
	 br label %L11
L13:
	 br label %L11
L11:
	 store i32 20, i32* %1
	 %39 = load i32, i32* %1
	 %40 = load i32, i32* %2
	 %41 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str8, i32 0, i32 0), i32 %39, i32 %40)
	 %42 = load i32, i32* %1
	 %43 = load i32, i32* %2
	 %44 = icmp ne i32 %42, %43
	 br i1 %44, label %L14, label %L15
L14:
	 %45 = load i32, i32* %1
	 %46 = load i32, i32* %2
	 %47 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str9, i32 0, i32 0), i32 %45, i32 %46)
	 br label %L15
L15:
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

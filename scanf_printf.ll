@.str9 = private unnamed_addr constant [15 x i8] c"Character: %c\0A\00"
@.str8 = private unnamed_addr constant [12 x i8] c"String: %s\0A\00"
@.str7 = private unnamed_addr constant [17 x i8] c"Integers: %d %d\0A\00"
@.str6 = private unnamed_addr constant [4 x i8] c"\0A%c\00"
@.str5 = private unnamed_addr constant [20 x i8] c"Enter a character:\0A\00"
@.str4 = private unnamed_addr constant [3 x i8] c"%s\00"
@.str3 = private unnamed_addr constant [17 x i8] c"Enter a string:\0A\00"
@.str2 = private unnamed_addr constant [6 x i8] c"%d %d\00"
@.str1 = private unnamed_addr constant [28 x i8] c"Enter two integer numbers:\0A\00"
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
	 %2 = alloca i32
	 %3 = alloca [64 x i8]
	 %4 = alloca i8
	 store i8 99, i8* %4
	 %5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([28 x i8], [28 x i8]* @.str1, i32 0, i32 0))
	 %6= call i32 (i8*, ...) @__isoc99_scanf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str2, i32 0, i32 0), i32* %1, i32* %2)
	 %7 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str3, i32 0, i32 0))
	 %8 = getelementptr inbounds [64 x i8], [64 x i8]* %3, i32 0, i32 0
	 %9= call i32 (i8*, ...) @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str4, i32 0, i32 0), i8* %8)
	 %10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([20 x i8], [20 x i8]* @.str5, i32 0, i32 0))
	 %11= call i32 (i8*, ...) @__isoc99_scanf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str6, i32 0, i32 0), i8* %4)
	 %12 = load i32, i32* %1
	 %13 = load i32, i32* %2
	 %14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str7, i32 0, i32 0), i32 %12, i32 %13)
	 %15 = getelementptr inbounds [64 x i8], [64 x i8]* %3, i8 0, i32 0
	 %16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str8, i32 0, i32 0), i8* %15)
	 %17 = load i8, i8* %4
	 %18 = sext i8 %17 to i32
	 %19 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str9, i32 0, i32 0), i32 %18)
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

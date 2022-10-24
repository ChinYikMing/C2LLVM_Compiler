@.str4 = private unnamed_addr constant [2 x i8] c"*\00"
@.str3 = private unnamed_addr constant [3 x i8] c"*\0A\00"
@.str2 = private unnamed_addr constant [3 x i8] c"%d\00"
@.str1 = private unnamed_addr constant [51 x i8] c"Enter the size of the triangle(positive integer):\0A\00"
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
	 store i32 0, i32* %1
	 %2 = alloca i32
	 store i32 0, i32* %2
	 %3 = alloca i32
	 %4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([51 x i8], [51 x i8]* @.str1, i32 0, i32 0))
	 %5= call i32 (i8*, ...) @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str2, i32 0, i32 0), i32* %3)
	 br label %L1
L1:
	 %6 = load i32, i32* %1
	 %7 = load i32, i32* %3
	 %8 = icmp slt i32 %6, %7
	 br i1 %8, label %L2, label %L3
L2:
	 store i32 0, i32* %2
	 br label %L4
L4:
	 %9 = load i32, i32* %2
	 %10 = load i32, i32* %1
	 %11 = icmp sle i32 %9, %10
	 br i1 %11, label %L5, label %L6
L5:
	 %12 = load i32, i32* %2
	 %13 = load i32, i32* %1
	 %14 = icmp eq i32 %12, %13
	 br i1 %14, label %L7, label %L8
L7:
	 %15 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str3, i32 0, i32 0))
	 br label %L9
L8:
	 %16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str4, i32 0, i32 0))
	 br label %L9
L9:
	 %17 = load i32, i32* %2
	 %18 = add nsw i32 %17, 1
	 store i32 %18, i32* %2
	 br label %L4
L6:
	 %19 = load i32, i32* %1
	 %20 = add nsw i32 %19, 1
	 store i32 %20, i32* %1
	 br label %L1
L3:
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

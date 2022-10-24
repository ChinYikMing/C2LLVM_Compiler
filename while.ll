@.str2 = private unnamed_addr constant [13 x i8] c"arr[%d]: %d\0A\00"
@arr1 = private unnamed_addr constant [10 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10]
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
	 %1 = alloca [10 x i32]
	 %2 = bitcast [10 x i32]* %1 to i8*
	 call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* bitcast ([10 x i32]* @arr1 to i8*), i64 40, i32 1, i1 false)
	 %3 = alloca i32
	 store i32 10, i32* %3
	 %4 = alloca i32
	 store i32 0, i32* %4
	 br label %L1
L1:
	 %5 = load i32, i32* %4
	 %6 = load i32, i32* %3
	 %7 = icmp slt i32 %5, %6
	 br i1 %7, label %L2, label %L3
L2:
	 %8 = load i32, i32* %4
	 %9 = alloca i32
	 store i32 8, i32* %9
	 %10 = load i32, i32* %9
	 %11 = icmp eq i32 %8, %10
	 br i1 %11, label %L4, label %L5
L4:
	 br label %L3
L5:
	 %12 = load i32, i32* %4
	 %13 = alloca i32
	 store i32 5, i32* %13
	 %14 = load i32, i32* %13
	 %15 = icmp eq i32 %12, %14
	 br i1 %15, label %L7, label %L8
L7:
	 %16 = load i32, i32* %4
	 %17 = add nsw i32 %16, 1
	 store i32 %17, i32* %4
	 br label %L1
L8:
	 %18 = load i32, i32* %4
	 %19 = getelementptr inbounds [10 x i32], [10 x i32]* %1, i32 0, i32 %18
	 %20 = load i32, i32* %4
	 %21 = add nsw i32 %20, 1
	 store i32 %21, i32* %19
	 %22 = load i32, i32* %4
	 %23 = getelementptr inbounds [10 x i32], [10 x i32]* %1, i32 0, i32 %22
	 %24 = load i32, i32* %4
	 %25 = load i32, i32* %23
	 %26 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str2, i32 0, i32 0), i32 %24, i32 %25)
	 %27 = load i32, i32* %4
	 %28 = add nsw i32 %27, 1
	 store i32 %28, i32* %4
	 br label %L6
L6:
	 br label %L1
L3:
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

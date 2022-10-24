@.str5 = private unnamed_addr constant [36 x i8] c"arr[0]: %d, arr[1]: %d, arr[2]: %d\0A\00"
@.str4 = private unnamed_addr constant [19 x i8] c"str: %s, str2: %s\0A\00"
@arr3 = private unnamed_addr constant [3 x i32] [i32 45, i32 46, i32 47]
@str22 = private unnamed_addr constant [3 x i8] c"abc"
@.str1 = private unnamed_addr constant [6 x i8] c"apple\00"
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
	 %1 = alloca [6 x i8]
	 %2 = bitcast [6 x i8]* %1 to i8*
	 call void @llvm.memcpy.p0i8.p0i8.i64(i8* %2, i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str1, i32 0, i32 0), i64 6, i32 1, i1 false)
	 %3 = alloca [3 x i8]
	 %4 = bitcast [3 x i8]* %3 to i8*
	 call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @str22, i32 0, i32 0), i64 3, i32 1, i1 false)
	 %5 = alloca [3 x i32]
	 %6 = bitcast [3 x i32]* %5 to i8*
	 call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* bitcast ([3 x i32]* @arr3 to i8*), i64 12, i32 1, i1 false)
	 %7 = getelementptr inbounds [6 x i8], [6 x i8]* %1, i8 0, i32 0
	 %8 = getelementptr inbounds [3 x i8], [3 x i8]* %3, i8 0, i32 0
	 %9 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([19 x i8], [19 x i8]* @.str4, i32 0, i32 0), i8* %7, i8* %8)
	 %10 = getelementptr inbounds [3 x i32], [3 x i32]* %5, i32 0, i32 0
	 %11 = load i32, i32* %10
	 %12 = getelementptr inbounds [3 x i32], [3 x i32]* %5, i32 0, i32 1
	 %13 = load i32, i32* %12
	 %14 = getelementptr inbounds [3 x i32], [3 x i32]* %5, i32 0, i32 2
	 %15 = load i32, i32* %14
	 %16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([36 x i8], [36 x i8]* @.str5, i32 0, i32 0), i32 %11, i32 %13, i32 %15)
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

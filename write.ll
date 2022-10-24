@.str4 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str3 = private unnamed_addr constant [13 x i8] c"testfile.txt\00"
@.str2 = private unnamed_addr constant [7 x i8] c"banana\00"
@.str1 = private unnamed_addr constant [13 x i8] c"testfile.txt\00"
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
	 %2 = call i32 (i8*, i32, ...) @open(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str1, i32 0, i32 0), i32 1)
	 store i32 %2, i32* %1
	 %3 = alloca [7 x i8]
	 %4 = bitcast [7 x i8]* %3 to i8*
	 call void @llvm.memcpy.p0i8.p0i8.i64(i8* %4, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str2, i32 0, i32 0), i64 7, i32 1, i1 false)
	 %5 = alloca i32
	 %6 = getelementptr inbounds [7 x i8], [7 x i8]* %3, i32 0, i32 0
	 %7 = call i64 @strlen(i8* %6)
	 %8 = trunc i64 %7 to i32
	 store i32 %8, i32* %5
	 %9 = load i32, i32* %1
	 %10 = getelementptr inbounds [7 x i8], [7 x i8]* %3, i32 0, i32 0
	 %11 = load i32, i32* %5
	 %12 = call i32 (i32, i8*, i32, ...) bitcast (i32 (...)* @write to i32 (i32, i8*, i32, ...)*)(i32 %9, i8* %10, i32 %11)
	 %13 = load i32, i32* %1
	 %14 = call i32 (i32, ...) bitcast (i32 (...)* @close to i32 (i32, ...)*)(i32 %13)
	 %15 = call i32 (i8*, i32, ...) @open(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str3, i32 0, i32 0), i32 0)
	 store i32 %15, i32* %1
	 %16 = alloca [64 x i8]
	 %17 = load i32, i32* %1
	 %18 = getelementptr inbounds [64 x i8], [64 x i8]* %16, i32 0, i32 0
	 %19 = load i32, i32* %5
	 %20 = call i32 (i32, i8*, i32, ...) bitcast (i32 (...)* @read to i32 (i32, i8*, i32, ...)*)(i32 %17, i8* %18, i32 %19)
	 %21 = getelementptr inbounds [64 x i8], [64 x i8]* %16, i8 0, i32 0
	 %22 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str4, i32 0, i32 0), i8* %21)
	 %23 = load i32, i32* %1
	 %24 = call i32 (i32, ...) bitcast (i32 (...)* @close to i32 (i32, ...)*)(i32 %23)
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

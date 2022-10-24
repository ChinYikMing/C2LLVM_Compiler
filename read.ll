@.str2 = private unnamed_addr constant [9 x i8] c"buf: %s\0A\00"
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
	 %2 = call i32 (i8*, i32, ...) @open(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str1, i32 0, i32 0), i32 0)
	 store i32 %2, i32* %1
	 %3 = alloca [64 x i8]
	 %4 = load i32, i32* %1
	 %5 = getelementptr inbounds [64 x i8], [64 x i8]* %3, i32 0, i32 0
	 %6 = call i32 (i32, i8*, i32, ...) bitcast (i32 (...)* @read to i32 (i32, i8*, i32, ...)*)(i32 %4, i8* %5, i32 64)
	 %7 = getelementptr inbounds [64 x i8], [64 x i8]* %3, i8 0, i32 0
	 %8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str2, i32 0, i32 0), i8* %7)
	 %9 = load i32, i32* %1
	 %10 = call i32 (i32, ...) bitcast (i32 (...)* @close to i32 (i32, ...)*)(i32 %9)
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

@.str12 = private unnamed_addr constant [15 x i8] c"After: a = %d\0A\00"
@.str11 = private unnamed_addr constant [33 x i8] c"Compute: a = (a / 100) * -1 + b\0A\00"
@.str10 = private unnamed_addr constant [24 x i8] c"Before: a = %d, b = %d\0A\00"
@.str9 = private unnamed_addr constant [15 x i8] c"After: a = %d\0A\00"
@.str8 = private unnamed_addr constant [36 x i8] c"Compute: a = b * (25 + a) + 90 - a\0A\00"
@.str7 = private unnamed_addr constant [24 x i8] c"Before: a = %d, b = %d\0A\00"
@.str6 = private unnamed_addr constant [15 x i8] c"After: a = %d\0A\00"
@.str5 = private unnamed_addr constant [34 x i8] c"Compute: a = (a + 60) * (a + 70)\0A\00"
@.str4 = private unnamed_addr constant [16 x i8] c"Before: a = %d\0A\00"
@.str3 = private unnamed_addr constant [15 x i8] c"After: a = %d\0A\00"
@.str2 = private unnamed_addr constant [32 x i8] c"Compute: a = b + 2 * (100 - 1)\0A\00"
@.str1 = private unnamed_addr constant [24 x i8] c"Before: a = %d, b = %d\0A\00"
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
	 store i32 3, i32* %1
	 %2 = alloca i32
	 store i32 5, i32* %2
	 %3 = load i32, i32* %1
	 %4 = load i32, i32* %2
	 %5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str1, i32 0, i32 0), i32 %3, i32 %4)
	 %6 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([32 x i8], [32 x i8]* @.str2, i32 0, i32 0))
	 %7 = alloca i32
	 store i32 100, i32* %7
	 %8 = load i32, i32* %7
	 %9 = sub nsw i32 %8, 1
	 %10 = mul nsw i32 %9, 2
	 %11 = load i32, i32* %2
	 %12 = add nsw i32 %11, %10
	 store i32 %12, i32* %1
	 %13 = load i32, i32* %1
	 %14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str3, i32 0, i32 0), i32 %13)
	 %15 = load i32, i32* %1
	 %16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([16 x i8], [16 x i8]* @.str4, i32 0, i32 0), i32 %15)
	 %17 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([34 x i8], [34 x i8]* @.str5, i32 0, i32 0))
	 %18 = load i32, i32* %1
	 %19 = add nsw i32 %18, 60
	 %20 = load i32, i32* %1
	 %21 = add nsw i32 %20, 70
	 %22 = mul nsw i32 %19, %21
	 store i32 %22, i32* %1
	 %23 = load i32, i32* %1
	 %24 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str6, i32 0, i32 0), i32 %23)
	 %25 = load i32, i32* %2
	 %26 = add nsw i32 %25, 10
	 store i32 %26, i32* %2
	 %27 = load i32, i32* %1
	 %28 = load i32, i32* %2
	 %29 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str7, i32 0, i32 0), i32 %27, i32 %28)
	 %30 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([36 x i8], [36 x i8]* @.str8, i32 0, i32 0))
	 %31 = load i32, i32* %1
	 %32 = add nsw i32 %31, 25
	 %33 = load i32, i32* %2
	 %34 = mul nsw i32 %33, %32
	 %35 = add nsw i32 %34, 90
	 %36 = load i32, i32* %1
	 %37 = sub nsw i32 %35, %36
	 store i32 %37, i32* %1
	 %38 = load i32, i32* %1
	 %39 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str9, i32 0, i32 0), i32 %38)
	 store i32 3000, i32* %2
	 %40 = load i32, i32* %1
	 %41 = load i32, i32* %2
	 %42 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str10, i32 0, i32 0), i32 %40, i32 %41)
	 %43 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([33 x i8], [33 x i8]* @.str11, i32 0, i32 0))
	 %44 = load i32, i32* %1
	 %45 = sdiv i32 %44, 100
	 %46 = mul nsw i32 %45, -1
	 %47 = load i32, i32* %2
	 %48 = add nsw i32 %46, %47
	 store i32 %48, i32* %1
	 %49 = load i32, i32* %1
	 %50 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str12, i32 0, i32 0), i32 %49)
	 br label %Lend
; === epilogue ===
Lend:
	 ret i32 0
}

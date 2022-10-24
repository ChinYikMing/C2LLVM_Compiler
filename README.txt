環境需求：
1. JDK 或 JRE
2. make
3. clang, lli, llc
Note: 請確保 JDK 或 JRE 的 java 和 javac 程式有設定到 path，不然無法執行 Makefile。我電腦的 JDK 是 openjdk version "11.0.9.1" 2020-11-04
Note: 請確保安裝了 clang，lli，llc ，不然無法執行 LLVM IR 檔案。我電腦有的 lli 和 llc 的版本為 6.0.0 和 10.0.0

提供了8個測試 C 程式檔，分別是 arithmetic.c, array_init_printf.c, cmp.c, read.c, write.c, scanf_printf.c, while.c, while_nested.c

Makefile 編譯與執行步驟：
1. 直接輸入 make，會得到8個測試 C 程式檔的 LLVM IR。例如 arithmetic.ll 是 arithmetic.c 的 LLVM IR
2. 如果想單獨得到某測試 C 程式檔的 LLVM IR，可以輸入 make 後面接上測試 C 程式檔名。例如 make arithmetic 會得到 arithmetic.c 測試檔的 LLVM IR
   （Note: 想要單獨得到某測試 C 程式檔的 LLVM IR，必須先輸入 make compiler 得到 compiler 除非之前已經編譯過了 compiler）

直譯執行 LLVM IR(.ll 檔案)：
輸入 lli 後面接上 .ll 檔案。例如 lli arithmetic.ll 會執行 arithmetic.c 的 LLVM IR 檔案

編譯 LLVM IR(.ll 檔案) 成組合語言：
輸入 llc 後面接上 .ll 檔案。例如 lli arithmetic.ll 會編譯成 arithmetic.s 檔案 

編譯成 target machine 執行檔：
1. 若是使用 gcc，在編譯 .s 檔案的時候加上 -static 參數。例如 gcc -static arithmetic.s，，最後會生成 a.out 執行檔
2. 若是使用 clang，則無需加入 。例如 clang arithmetic.s，最後會生成 a.out 執行檔

若想刪除所有相關 make 生成的檔案，輸入 make clean 即可



測試 C　程式檔說明：
1. arithmetic.c，包含了 +, -, *, /，負數算術運算， printf 函數
2. array_init_printf.c，包含了 char 陣列和 int 陣列初始化和存取， printf 函數
3. cmp.c，包含了 >, >=, <, <=, ==, != ， printf 函數
4. read.c, 包含了 open, read, close 函數， printf 函數
5. write.c, 包含了 open, write, read, close 函數， printf 函數。
6. scanf_printf.c，包含了 scanf, printf 函數
7. while.c, 包含了 while, break, continue, int 陣列初始化和存取， printf 函數
8. while_nested.c，包含了雙層 while。輸入一個正整數會印出直角三角形， printf 函數



C subset 說明：
1. 支援 +, -, *, /, >, >=, <, <=, ==, != 運算。
	Note: 先乘除後加減
2. 支援資料型別： int, char, int 陣列， char 陣列。int 陣列支援 { ... } 初始化，char 陣列支援 string-literal 和 {'x', ...} 初始化
	- 陣列初始化大小如果沒有宣告，會依據初始化的元素個數決定陣列大小。例如 char buf[] = "apple", buf 的長度就會是 apple 的長度加上 NULL character 決定（5 + 1 = 6）
	- 如果陣列初始化大小比初始化元素個數少，那麼多出來的元素個數會被丟棄（ truncate ）。例如 char buf[5] = "applepie"，最後 buf 只會剩下 apple
	- 可以使用變數或整數當作陣列的 index。例如 int arr[] = {1, 2, 3}, int a = 1。 arr[a] 和 arr[1] 是同樣的作用。
3. 支援多層 while 迴圈
4. 支援函數： main, scanf(支援多個變數), printf（支援多個變數）, strlen, open, read, write, close
5. 支援 keywords: return, continue, break

.SILENT: compiler

all: compiler arithmetic array_init_printf cmp read write scanf_printf while while_nested

compiler:
	java -cp antlr-3.5.2-complete.jar org.antlr.Tool myCompiler.g 2> /dev/null
	javac -Xlint -cp ./antlr-3.5.2-complete.jar myCompiler_test.java myCompilerParser.java myCompilerLexer.java

arithmetic: arithmetic.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

array_init_printf: array_init_printf.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

cmp: cmp.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

read: read.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

write: write.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

scanf_printf: scanf_printf.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

while: while.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

while_nested: while_nested.c
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test $^ > $(addsuffix .ll,$@)

.PHONY: clean
clean:
	rm -f *.ll *.tokens *.class myCompilerLexer.java myCompilerParser.java

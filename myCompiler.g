grammar myCompiler;

options {
  language = Java;
}

@header {
	import java.util.HashMap;
	import java.util.List;
	import java.util.ArrayList;
	import java.util.Iterator;
	import java.util.Arrays;
	import java.util.Scanner;
}

@members {
	/* type */
	int ERR = -1;
	int INTEGER = 0;
	int DOUBLE = 1;
	int INTEGER_ARRAY = 2;
	int CONST_INTEGER = 3;
	int CONST_DOUBLE = 4;
	int CHARACTER = 5;
	int CHARACTER_ARRAY = 6;
	
	String intType = "\%d";
	String doubleType = "\%lf";
    boolean TRACEON = false;
	Boolean inlineDecl = false;
	int prevType = ERR;
	Boolean isBracketArith = false; // fixme: refactoring
	Boolean isInnestIfLayer = true;
	Boolean isInnestElseIfLayer = true;
	int labelIdx = 0;
	String arrayInitID;

	ArrayList<String> endLabelList = new ArrayList<>();
	ArrayList<Boolean> hasElseIfOrElseList = new ArrayList<>(); // for nested conditional
	String ifFalseLabel;
	int elseifCnt = 0;

	String while_init_label, while_false_label;
	Boolean has_break = false, has_continue = false;

	String variableNew, variableNew1, variableNew2, variableNew3;

	/* class for store info of primary_expression */
	class VarInfo {
	    private int type;
	    private Object val;
	    private String id;
		private Boolean isLoad = false;
		private Boolean isNeg = false;
		private int arraySize = 0;

	    VarInfo(){

	    }

	    String getID(){
	        return id;
	    }

	    void setID(String id){
	        this.id = id;
	    }

		int getArraySize(){
			return arraySize;
		}

		void setArraySize(int size){
			this.arraySize = size;
		}

		Boolean getIsNeg(){
			return isNeg;
		}

		void setIsNeg(Boolean b){
			this.isNeg = b;
		}

	    int getType(){
	        return type;
	    }

	    Object getVal(){
	        return val;
	    }

		Boolean getIsLoad(){
			return isLoad;
		}

		void setIsLoad(Boolean isLoad){
			this.isLoad = isLoad;
		}

	    void setType(int type){
	        this.type = type;
	    }

	    void setVal(Object val){
	        this.val = val;
	    }
	}

	/* store variable and its info */
	HashMap<String, VarInfo> symtab = new HashMap<String, VarInfo>();

	/* for conditional checking */
	Boolean hasOr = false;
	Boolean hasAnd = false;
	Boolean hasTrueOnce = false;
	Boolean hasFalseOnce = false;
	Boolean valid = false;
	Boolean conditionalDone = false;
	Boolean reachConditionalStatement = false;

	// global string
	String str;

	// global string buffer
	int strbufSize = 256;
	StringBuffer strbuf = new StringBuffer(strbufSize); // fixme: constant buffer size
	int start;
	int end;

	String scanType;
	String printType;
	List<String> scanTypeList = new ArrayList<String>();
	List<String> printTypeList = new ArrayList<String>();
	int scanTypeIdx = 0;
	int printTypeIdx = 0;

	Scanner terminal = new Scanner(System.in);

	/* class for label generation */
	class LabelGenerator {
        int labelIdx = 1;
		private List<String> falseLabelList = new ArrayList<String>(); // for nested

        LabelGenerator(){

        }

        String getLabel(){
            setLabel();
            return "L" + (labelIdx - 1);
        }

		int getLabelIdx(){
			return labelIdx;
		}

		void pushFalseLabel(String label){
			falseLabelList.add(label);
		}
		
		String getFalseLabel(){
			// System.out.println("get size " + falseLabelList.size());
			return falseLabelList.get(falseLabelList.size() - 1);
		}

		String popFalseLabel(){
			return falseLabelList.remove(falseLabelList.size() - 1);
		}

		int getFalseLabelListSize(){
			return falseLabelList.size();
		}

        private void setLabel(){
            labelIdx += 1;
        }

        String getLabelByIdx(int n){
			if(n < 0 || n > labelIdx){
				System.out.println("getLabelByIdx out of bound");
				System.exit(1);
			}

            return "L" + n;
        }
	}

	/* class for variable generation */
	class VariableGenerator {
        int variableIdx = 1;
		int globVariableIdx = 1;

        VariableGenerator(){

        }

        String getVariable(){
            setVariable();
            return "\%" + (variableIdx - 1);
        }

		String getGlobalVariable(String prefix){
			setGlobalVariable();
			return prefix + (globVariableIdx - 1);
		}

		private void setGlobalVariable(){
			globVariableIdx += 1;
		}

        private void setVariable(){
            variableIdx += 1;
        }

        String getPrevVariable(){
            if(variableIdx == 0)
                return "\%0";
            return "\%" + (variableIdx - 1);
        }
	}

	/* class for LLVM IR generation */
	class LLVMIRGenerator {
	    static final int defaultBufferSize = 256;
	    private StringBuffer llvmIr;
	    private LabelGenerator labelGenerator;
	    private VariableGenerator variableGenerator;
		private int retVal;

		LLVMIRGenerator() {
            llvmIr = new StringBuffer(defaultBufferSize);
            init();
		}

		LLVMIRGenerator(int size) {
            llvmIr = new StringBuffer(size);
            init();
		}

		void init(){
            labelGenerator = new LabelGenerator();
            variableGenerator = new VariableGenerator();
            prologue();
		}

		String asciiTransform(String str){
			StringBuilder ret = new StringBuilder();
			ret.append(str);

			int newLineOffset = 0;
			while((newLineOffset = ret.indexOf("\\n", newLineOffset)) != -1){
				ret.replace(newLineOffset, newLineOffset + 2, "\\0A");
			}

			int tabOffset = 0;
			while((tabOffset = ret.indexOf("\\t", tabOffset)) != -1){
				ret.replace(tabOffset, tabOffset + 2, "\\09");
			}
			ret.append("\\00");
			return ret.toString();
		}

		int asciiStrLen(String asciiStr){
			int len = 0;

			for(int i = 0; i < asciiStr.length();){
				len++;

				if(asciiStr.charAt(i) == '\\' && asciiStr.charAt(i + 1) == '0'){
					i += 3;
				} else {
					i++;
				}
			}

			return len;
		}

		void prologue(){
		   insert("; === prologue ====\n");

		   insert("declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i32, i1)\n");
		   insert("declare dso_local i32 @__isoc99_scanf(i8*, ...)\n");
		   insert("declare dso_local i32 @printf(i8*, ...)\n");
		   insert("declare dso_local i64 @strlen(i8*)\n");

		   insert("declare dso_local i32 @open(i8*, i32, ...)\n");
		   insert("declare dso_local i32 @read(...)\n");
		   insert("declare dso_local i32 @write(...)\n");
		   insert("declare dso_local i32 @close(...)\n");

		   insert("define dso_local i32 @main(){\n");
		}

		void epilogue(int retVal){
		   insert("; === epilogue ===\n");
		   insert("Lend:\n");
		   insert("\t ret i32 " + retVal);
		   insert("\n}");
		}

		int getRetVal(){
			return retVal;
		}

		void setRetVal(int retVal){
			this.retVal = retVal;
		}

		String genLlvmIr(){
		    epilogue(getRetVal());
			return llvmIr.toString();
		}

		void insert(String ll){
		    llvmIr.append(ll);
		}

		void insertFront(String ll){
			llvmIr.insert(0, ll);
		}
	}

	LLVMIRGenerator llvmIrGenerator = new LLVMIRGenerator();
}

start_parsing // translation unit start
	:	  include_header (declarator_list)*  main
      {
        if (TRACEON) System.out.println("\nstart parsing from here:\n" + $start_parsing.text.toString());
        String llvmIr = llvmIrGenerator.genLlvmIr();
        System.out.println(llvmIr);
      }
	;

main: INT_TYPE MAIN_FUNC '(' function_parameter_list? ')' '{' (statement_list)* '}'
      {
		llvmIrGenerator.insert("\t br label \%Lend\n");
        if (TRACEON) System.out.println("\nmain function:\n" + $main.text.toString());
      }
	;

define_expression
	:	DEFINE_TYPE ID . // need to save to hash map for preprocessing
	;

include_from_sys
	:	INCLUDE_TYPE INCLUDE_SYSLIB_TYPE;

include_from_own
	:	INCLUDE_TYPE LITERAL;

include_header
	:	(include_from_sys | include_from_own)*
      {if (TRACEON) System.out.println("\ninclude header file:\n" + $include_header.text.toString());}
	;

function_parameter_list
	:	declarator_type (',' declarator_type)* (',' DOT_DOT_DOT)?;

function_declarator
	:	((type | VOID_TYPE) ID '(')=>(type | VOID_TYPE) ID '(' function_parameter_list? ')' function_declarator_end
	;

function_declarator_end
	:	';' | function_expression;

function_expression
	:	'{' (statement)* '}';

declarator_list
	: d=declarator 
	{ 
		if(prevType == ERR)
			prevType = $d.t; 
	} (',' { inlineDecl = true; } declarator)* { inlineDecl = false; prevType = ERR; }
      {if (TRACEON) System.out.println("\nvariable declaration:\n" + $declarator_list.text.toString());}
	| function_declarator
      {if (TRACEON) System.out.println("\nfunction declaration:\n" + $declarator_list.text.toString());}
	| struct_declarator
      {if (TRACEON) System.out.println("\nstructure declaration:\n" + $declarator_list.text.toString());}
	| define_expression
      {if (TRACEON) System.out.println("\ndefine expression:\n" + $declarator_list.text.toString());}
	;

declarator_type returns [int type, String id, Boolean isArray, int arraySize, String loadVariable]
	: VOID_TYPE // void type is special type which do not require an ID, fixme
	| t=type decl
	{
		if(symtab.containsKey($decl.id)){ // redeclaration
            System.out.println("Type Error: redeclared identifier: " + $decl.id);
            System.exit(0);
		}

		$id = $decl.id;

		if($t.text.toString().equals("int")){
			$type = INTEGER;
		} else if($t.text.toString().equals("char")){
			$type = CHARACTER;
		}
		$isArray = $decl.isArray;
		$arraySize = $decl.arraySize;
		$loadVariable = $decl.loadVariable;
	}
	| decl
	{
		$id = $decl.id;
		$type = ERR;
		$isArray = $decl.isArray;
		$arraySize = $decl.arraySize;
		$loadVariable = $decl.loadVariable;
	}
	;

decl returns [String id, Boolean isArray, int arraySize, String loadVariable]
	:	n=normal_declarator
	{
		$id = $n.id;
		$isArray = $n.isArray;
		$arraySize = $n.arraySize;
		$loadVariable = $n.loadVariable;
	}
	| (pointer_declarator)* normal_declarator
	;

declarator
returns [int t]
@init{
    int val;
    String variableIdxStr;
    VarInfo info;
	int arraySize = -100;
	String dataTypeSize = null;
}
	: id=declarator_type {
		$t = $id.type;

		if(($id.type == ERR && inlineDecl) || ($id.type != ERR)){ // variable declaration
			info = new VarInfo();
			variableNew = llvmIrGenerator.variableGenerator.getVariable();
			info.setID($id.id);
			info.setVal(variableNew);

			if($id.isArray != null && $id.isArray){
				arraySize = $id.arraySize;
				info.setArraySize(arraySize);

				dataTypeSize = null;
				if($id.type == INTEGER){
					dataTypeSize = "i32";
					info.setType(INTEGER_ARRAY);
				} else if($id.type == CHARACTER){
					dataTypeSize = "i8";
					info.setType(CHARACTER_ARRAY);
				}

				if(arraySize != 0){ // -2 indicates empty size during declaration
					llvmIrGenerator.insert("\t " + variableNew + " = alloca " + "[" + arraySize + " x " + dataTypeSize + "]\n");
				}
			} else {
				if($id.type == INTEGER){
					info.setType(INTEGER);
					llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");
				} else if($id.type == CHARACTER){
					info.setType(CHARACTER); // fixme
					llvmIrGenerator.insert("\t " + variableNew + " = alloca i8\n");
				} else if(inlineDecl){
					if(prevType == INTEGER){
						info.setType(INTEGER);
						llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");
					} else if(prevType == CHARACTER){
						info.setType(CHARACTER);
						llvmIrGenerator.insert("\t " + variableNew + " = alloca i8\n");
					}
				}
			}
			symtab.put($id.id, info);
			arrayInitID = $id.id;

		} else if($id.type == ERR){ // variable accessment
			info = symtab.get($id.id);
			if(info == null){ // variable undefined
				System.out.println("Undefined variable: " + $id.id);
				System.exit(0);
			}

			// variable exists
			int type = info.getType();
			if(type == INTEGER){

			} else if(type == CHARACTER){

			} else if(type == INTEGER_ARRAY){
			} else if(type == CHARACTER_ARRAY){

			}
				// System.out.println("here");
		}
	} ((assign_op i=initializer {
		if($i.varInfo != null){
			VarInfo idInfo = symtab.get($id.id);
			String variablePrev = llvmIrGenerator.variableGenerator.getPrevVariable();

			int type = $i.varInfo.getType();
			if(type == INTEGER){
				if($id.isArray != null && $id.isArray){
					if(idInfo.getType() == INTEGER_ARRAY){
						if($id.arraySize == -1){ // store to previous variable is OK
							llvmIrGenerator.insert("\t store i32 " + variablePrev  + ", " +
													"i32* " + $id.loadVariable + "\n");
						} else {
							String variableNew = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + idInfo.getArraySize() + " x i32], " +  
										"[" + idInfo.getArraySize() +  " x i32]* " + (String) idInfo.getVal() + ", i32 0, i32 " + $id.arraySize + "\n");

							llvmIrGenerator.insert("\t store i32 " + variableNew + ", " +
													"i32* " + variablePrev + "\n");
						}
					} else if(idInfo.getType() == CHARACTER_ARRAY){
						// System.out.println("string declar");
					}
				} else {
					variableIdxStr = (String) idInfo.getVal();

					llvmIrGenerator.insert("\t store i32 " + variablePrev + ", " +
											"i32* " + variableIdxStr + "\n");
				}
			} else if(type == CONST_INTEGER){
				if($id.isArray != null && $id.isArray){
					if(idInfo.getType() == INTEGER_ARRAY){

						val = (int) $i.varInfo.getVal();

						if($id.arraySize == -1){ // store to previous variable is OK
							llvmIrGenerator.insert("\t store i32 " + val + ", " +
													"i32* " + variablePrev + "\n");
						} else {
							String variableNew = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + idInfo.getArraySize() + " x i32], " +  
										"[" + idInfo.getArraySize() +  " x i32]* " + (String) idInfo.getVal() + ", i32 0, i32 " + $id.arraySize + "\n");

							llvmIrGenerator.insert("\t store i32 " + val + ", " +
												"i32* " + variableNew + "\n");
						}
					} else if(idInfo.getType() == CHARACTER_ARRAY){

					}
				} else {
					variableIdxStr = (String) idInfo.getVal();
					val = (int) $i.varInfo.getVal();

					llvmIrGenerator.insert("\t store i32 " + val + ", " +
											"i32* " + variableIdxStr + "\n");
				}
			} else if(type == CHARACTER_ARRAY){
				if($id.isArray != null && $id.isArray){
					if(idInfo.getType() != CHARACTER_ARRAY){
						System.out.println("TypeError: " + $id.id);
						System.exit(0);
					}
					String str = (String) $i.varInfo.getVal();

					if(arraySize < 0){
						System.out.println("Invalid array size for array: " + $id.id);
						System.exit(1);
					}

					if(arraySize != 0){
						if(arraySize < str.length()){
							System.out.println("LITERAL: " + str + " is too long for array: " + $id.id + "\n");
							System.exit(1);
						}

						int lenDiff = idInfo.getArraySize() - str.length();
						if(lenDiff > 0){ // need padding
							for(int j = 0; j < lenDiff - 1; j++){
								str += "\\00";
							}
						} else if(lenDiff < 0){ // need truncating
							str = str.substring(0, idInfo.getArraySize() - 1);
						}
					}

					// declare global string
					String variableNewGlobal = llvmIrGenerator.variableGenerator.getGlobalVariable(".str");
					String asciiStr = llvmIrGenerator.asciiTransform(str);
					int strlen = llvmIrGenerator.asciiStrLen(asciiStr);

					if(arraySize == 0){
						arraySize = strlen;
						idInfo.setArraySize(arraySize);
						llvmIrGenerator.insert("\t " + variablePrev + " = alloca " + "[" + arraySize + " x i8]\n");
					}

					llvmIrGenerator.insertFront("@" + variableNewGlobal + " = private unnamed_addr constant [" + strlen + " x i8] c" + "\"" + asciiStr + "\"\n");

					// call memcpy
					String variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = bitcast [" + idInfo.getArraySize() + " x i8]* " +  
								(String) idInfo.getVal() +  " to i8*\n");
					llvmIrGenerator.insert("\t call void @llvm.memcpy.p0i8.p0i8.i64(i8* " + variableNew + ", i8* getelementptr inbounds ([" + idInfo.getArraySize() + " x i8], " +  
								"[" + idInfo.getArraySize() +  " x i8]* @" + variableNewGlobal + ", i32 0, i32 0), i64 " + idInfo.getArraySize() + ", i32 1, i1 false)\n");
				} else {
					System.out.println("TypeError: " + $id.id);
					System.exit(0);
				}
			} else if(type == CHARACTER){
				if($i.varInfo.getType() != CHARACTER && $i.varInfo.getType() != INTEGER && 
					$i.varInfo.getType() != CONST_INTEGER){
						System.out.println("TypeError: " + $id.id);
						System.exit(0);
				}

				variableIdxStr = (String) idInfo.getVal();
				val = (int) $i.varInfo.getVal();

				llvmIrGenerator.insert("\t store i8 " + val + ", " +
										"i8* " + variableIdxStr + "\n");
			}
		}
	}) | assign_expr)? ';'?
	;

normal_declarator returns [String id, Boolean isArray, int arraySize, String loadVariable]
	:	ID 
	{
		$id = $normal_declarator.text.toString();
	} ((arr=array_declarator[$id] {$isArray = true; $arraySize = $arr.size; $loadVariable = $arr.loadVariable;})? ('\.'ID | '->'ID)? )
	;

pointer_declarator
	: '*'
	;

assign_op
	:	'+='
	| 	'*='
	| 	'/='
	| 	'-='
	| 	'%='
	| 	'<<='
	| 	'>>='
	| 	'&='
	| 	'|='
	| 	'^='
	|	'='
	;

array_declarator
[String id]
returns [int size, String loadVariable]
@init {
	int size;
}
	:	 ('[' e=expression? ']')+ 
	{
		VarInfo info = symtab.get($id);
		if(info == null){ // declaration stage
			if($e.varInfo == null){
				$size = 0;
				// System.out.println("empty size");
			} else {
				$size = (int) $e.varInfo.getVal(); // declaration only allowed constant integer
			}
		} else { // accessment
			// if e is a variable, we have to load it and calculate the offset

			int type = $e.varInfo.getType();

			if(type == INTEGER){ // variable
				int infoType = info.getType();

				if(infoType == INTEGER_ARRAY){
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
												(String) $e.varInfo.getVal() + "\n");


					variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew2 + " = getelementptr inbounds [" + info.getArraySize() + " x i32], " +  
								"[" + info.getArraySize() +  " x i32]* " + (String) info.getVal() + ", i32 0, i32 " + variableNew + "\n");

					$loadVariable =  variableNew2;
				} else if(infoType == CHARACTER_ARRAY){
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
												(String) $e.varInfo.getVal() + "\n");


					variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew2 + " = getelementptr inbounds [" + info.getArraySize() + " x i8], " +  
								"[" + info.getArraySize() +  " x i8]* " + (String) info.getVal() + ", i32 0, i32 " + variableNew + "\n");

					$loadVariable =  variableNew2;
				}

				$size = -1;
			} else if(type == CONST_INTEGER){
				$size = (int) $e.varInfo.getVal();
			}
		}
	};

array_expression
returns [VarInfo varInfo]
@init {
	StringBuilder strBuilder = new StringBuilder();
	int needToPad;
	String asciiStr;
	String str;
	int arraySize;
	VarInfo p1info = null, p2info = null;
	int type = ERR;
	char c;
	int v;
	ArrayList<Integer> vList = new ArrayList<>();
}
	:	'{' 
		'{'? p1=primary_expression? 
			{
				p1info = $p1.varInfo;
				type = p1info.getType();
				if(type == CHARACTER){
					c = (char)((int) p1info.getVal());
					strBuilder.append(c);
				} else if(type == CONST_INTEGER){
					v = (int) p1info.getVal();
					vList.add(v);
				}

				// System.out.println("arr decla");
			}
	    '}'? (',' '{'? 
			p2=primary_expression 
			{
				p2info = $p2.varInfo;
				type = p2info.getType();
				if(type == CHARACTER){
					c = (char)((int) p2info.getVal());
					strBuilder.append(c);
				} else if(type == CONST_INTEGER){
					v = (int) p2info.getVal();
					vList.add(v);
				}
			}
		'}'? ) * '}' 
	{
		VarInfo idInfo = symtab.get(arrayInitID);
		String varIdxStr = (String) idInfo.getVal();
		String id = idInfo.getID();
		arraySize = idInfo.getArraySize();

		if(type == CHARACTER){
			if(arraySize != 0){
				if(arraySize < strBuilder.length()){
					System.out.println("Invalid size to initialize array: " + id);
					System.exit(1);
				}

				// padding string builder if needed
				needToPad = arraySize - strBuilder.length();
				if(needToPad > 0){
					for(int i = 0; i < needToPad - 1; i++){
						strBuilder.append("\\00");
					}
					str = strBuilder.toString();
					asciiStr = llvmIrGenerator.asciiTransform(str);
				} else {
					str = strBuilder.toString();
					asciiStr = llvmIrGenerator.asciiTransform(str);
					asciiStr = asciiStr.substring(0, asciiStr.length() - 3);
				}
			} else {
				str = strBuilder.toString();
				asciiStr = llvmIrGenerator.asciiTransform(str);
				asciiStr = asciiStr.substring(0, asciiStr.length() - 3);

				// use str len to declare
				String variablePrev = llvmIrGenerator.variableGenerator.getPrevVariable();
				String dataTypeSize = "i8";
				arraySize = str.length();
				idInfo.setArraySize(arraySize);

				llvmIrGenerator.insert("\t " + variablePrev + " = alloca " + "[" + arraySize + " x " + dataTypeSize + "]\n");
			}

			// System.out.println(strBuilder.toString()); 

			// declare {...} in global
			String variableNewGlobal = llvmIrGenerator.variableGenerator.getGlobalVariable(arrayInitID);
			int strlen = llvmIrGenerator.asciiStrLen(asciiStr);

			llvmIrGenerator.insertFront("@" + variableNewGlobal + " = private unnamed_addr constant [" + strlen + " x i8] c" + "\"" + asciiStr + "\"\n");

			// System.out.println("array expression"); 

			// call memcpy
			String variableNew = llvmIrGenerator.variableGenerator.getVariable();
			llvmIrGenerator.insert("\t " + variableNew + " = bitcast [" + arraySize + " x i8]* " + varIdxStr + " to i8*\n");
			llvmIrGenerator.insert("\t call void @llvm.memcpy.p0i8.p0i8.i64(i8* " + variableNew + ", i8* getelementptr inbounds ([" + arraySize + " x i8], " +  
						"[" + arraySize +  " x i8]* @" + variableNewGlobal + ", i32 0, i32 0), i64 " + arraySize + ", i32 1, i1 false)\n");
		} else if(type == CONST_INTEGER){
			int len = vList.size();

			if(arraySize != 0){
				if(arraySize < vList.size()){
					System.out.println("Invalid size to initialize array: " + id);
					System.exit(1);
				}

				// padding value list if needed
				needToPad = arraySize - vList.size();
				if(needToPad > 0){
					for(int i = 0; i < needToPad; i++){
						vList.add(0);
					}
				}
			} else {
				String variablePrev = llvmIrGenerator.variableGenerator.getPrevVariable();
				String dataTypeSize = "i32";
				arraySize = len;
				idInfo.setArraySize(arraySize);

				llvmIrGenerator.insert("\t " + variablePrev + " = alloca " + "[" + arraySize + " x " + dataTypeSize + "]\n");
			}

			// declare {...} in global
			String variableNewGlobal = llvmIrGenerator.variableGenerator.getGlobalVariable(arrayInitID);

			String arrayString = "@" + variableNewGlobal + " = private unnamed_addr constant [" + len + " x i32] [";
			for(int i = 0; i < vList.size(); i++){
				if(i == vList.size() - 1){
					arrayString += ("i32 "+ vList.get(i) + "]\n");
					break;
				}
				arrayString += ("i32 "+ vList.get(i) + ", ");
			}
			llvmIrGenerator.insertFront(arrayString);

			// call memcpy
			String variableNew = llvmIrGenerator.variableGenerator.getVariable();
			int byteSize = len * 4;
			llvmIrGenerator.insert("\t " + variableNew + " = bitcast [" + len + " x i32]* " + varIdxStr + " to i8*\n");
			llvmIrGenerator.insert("\t call void @llvm.memcpy.p0i8.p0i8.i64(i8* " + variableNew + ", i8* bitcast ([" + len + " x i32]* @" +  
						variableNewGlobal + " to i8*), i64 " + byteSize + ", i32 1, i1 false)\n");
		}

		$varInfo = null;
	}
	|	ID '[' expression ']' 
	;

struct_declarator
	:	STRUCT_TYPE ID '{' (declarator_list)* '}' ';'
	;

struct_expression
	:	'{' '{'? struct_expr '}'?  (',' '{'? struct_expr '}'? )* '}'
	|	ID '\.' ID
	|	'&'? ID '->' ID
	;

struct_expr
	:	'\.' ID '=' primary_expression;  // C99 designator

type: INT_TYPE |
      CHAR_TYPE |
      FLOAT_TYPE |
      DOUBLE_TYPE|
      struct_type;

struct_type
	:	STRUCT_TYPE ID;

initializer
returns [VarInfo varInfo]
			: 
			l=LITERAL {
				String str = $l.text.toString();
				str = str.substring(1, str.length() - 1); // remove quote
				VarInfo info = new VarInfo();
				info.setType(CHARACTER_ARRAY);
				info.setVal(str);

				$varInfo = info;
			}
			| e=expression
			{
			    $varInfo = $e.varInfo;
				if(!$e.hasMultipleArith){ // single variable assignment
					// load
					// System.out.println("single init");
					if($e.varInfo.getType() == INTEGER){
						String eVarIdxStr = (String) $e.varInfo.getVal();
						variableNew = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
													eVarIdxStr + "\n");
					}
				}
			}
			| pointer_expression
			| a=array_expression { $varInfo = $a.varInfo; }
			| struct_expression
			| var=function_call_statement {
				VarInfo varinfo = new VarInfo();
				varinfo.setType(INTEGER);
				varinfo.setVal($var.variableNew);

				$varInfo = varinfo;
			}
			;

// normal_declarator
// 	:	ID ((array_declarator)? | ('\.'ID | '->'ID)? /* this is for structure */)
// 	;

/*----------------------*/
/*      statements      */
/*----------------------*/

dec_num
	: '-' DEC_NUM
	| DEC_NUM
	;
constant: dec_num | FLOAT_NUM | CHAR | LITERAL;

pointer_expression
	:	'&' ID | 'NULL'
	;

expression
returns [VarInfo varInfo, Boolean hasMultipleArith, Boolean valid, String cmpVar, String trueLabel, String falseLabel]
@init{
		int ires = 0;
		int ieres = 0;
		double dres = 0.0;
		double deres = 0.0;
		VarInfo info = new VarInfo();
}
		: { // initialization
			hasOr = false;
			hasAnd = false;
			hasTrueOnce = false;
			hasFalseOnce = false;
		} a = arith_expression {
            $varInfo = $a.varInfo;
			$hasMultipleArith = $a.hasMultipleArith;
		} (o = (COMPARE_OP | CONDITIONAL_OP ) e=expression {
			String opt = $o.text.toString();
			// System.out.println("opt: " + opt);

            int atype = $a.varInfo.getType();
			int etype = $e.varInfo.getType();
			String variableNew1, variableNew2, variableNew3 = null;
			String labelNew1, labelNew2;
			String aVarIdxStr, eVarIdxStr;

			if(atype == etype){
				if(atype == CONST_INTEGER){
					// alloc two variable, store integer to them and load them for comparison

					// alloc
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");
					variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew1 + " = alloca i32\n");

					// store
					int aVal = (int) $a.varInfo.getVal();
					llvmIrGenerator.insert("\t store i32 " + aVal + ", " +
												"i32* " + variableNew + "\n");
					int eVal = (int) $e.varInfo.getVal();
					llvmIrGenerator.insert("\t store i32 " + eVal + ", " +
												"i32* " + variableNew1 + "\n");

					// load
					variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
											variableNew + "\n");
					variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew3 + " = load i32, i32* " +
											variableNew1 + "\n");

					// camparison
					String variableNew4 = llvmIrGenerator.variableGenerator.getVariable();
					$cmpVar = variableNew4;

					if(opt.equals(">")){
						llvmIrGenerator.insert("\t " + variableNew4 + " = icmp sgt i32 " +
												variableNew2 + ", " + variableNew3 + "\n");
											
					} else if(opt.equals("<")){
						llvmIrGenerator.insert("\t " + variableNew4 + " = icmp slt i32 " +
												variableNew2 + ", " + variableNew3 + "\n");

					} else if(opt.equals("<=")){
						llvmIrGenerator.insert("\t " + variableNew4 + " = icmp sle i32 " +
												variableNew2 + ", " + variableNew3 + "\n");
											
					} else if(opt.equals(">=")){
						llvmIrGenerator.insert("\t " + variableNew4 + " = icmp sge i32 " +
												variableNew2 + ", " + variableNew3 + "\n");
											
					} else if(opt.equals("!=")){
						llvmIrGenerator.insert("\t " + variableNew4 + " = icmp ne i32 " +
												variableNew2 + ", " + variableNew3 + "\n");
											
					} else if(opt.equals("==")){
						llvmIrGenerator.insert("\t " + variableNew4 + " = icmp eq i32 " +
												variableNew2 + ", " + variableNew3 + "\n");
					}

					labelNew1 = llvmIrGenerator.labelGenerator.getLabel();
					labelNew2 = llvmIrGenerator.labelGenerator.getLabel();

					$trueLabel = labelNew1;
					$falseLabel = labelNew2;
					// llvmIrGenerator.insert("\t br i1 " + variableNew4 + ", label " +
					// 						"\%" + labelNew1 + ", label " + 
					// 						"\%" + labelNew2 + "\n");
					// llvmIrGenerator.insert(labelNew1 + ":\n");

					// llvmIrGenerator.labelGenerator.pushFalseLabel(labelNew2);
				} else if(atype == INTEGER){
					// load and cmp
					aVarIdxStr = (String) $a.varInfo.getVal();
					eVarIdxStr = (String) $e.varInfo.getVal();

					variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
												aVarIdxStr + "\n");

					variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
												eVarIdxStr + "\n");

					variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
					$cmpVar = variableNew3;

					if(opt.equals(">")){
						llvmIrGenerator.insert("\t " + variableNew3 + " = icmp sgt i32 " +
												variableNew1 + ", " + variableNew2 + "\n");
											
					} else if(opt.equals("<")){
						llvmIrGenerator.insert("\t " + variableNew3 + " = icmp slt i32 " +
												variableNew1 + ", " + variableNew2 + "\n");

					} else if(opt.equals("<=")){
						llvmIrGenerator.insert("\t " + variableNew3 + " = icmp sle i32 " +
												variableNew1 + ", " + variableNew2 + "\n");
											
					} else if(opt.equals(">=")){
						llvmIrGenerator.insert("\t " + variableNew3 + " = icmp sge i32 " +
												variableNew1 + ", " + variableNew2 + "\n");
											
					} else if(opt.equals("!=")){
						llvmIrGenerator.insert("\t " + variableNew3 + " = icmp ne i32 " +
												variableNew1 + ", " + variableNew2 + "\n");
											
					} else if(opt.equals("==")){
						llvmIrGenerator.insert("\t " + variableNew3 + " = icmp eq i32 " +
												variableNew1 + ", " + variableNew2 + "\n");
					}

					labelNew1 = llvmIrGenerator.labelGenerator.getLabel();
					labelNew2 = llvmIrGenerator.labelGenerator.getLabel();
					$trueLabel = labelNew1;
					$falseLabel = labelNew2;
					// llvmIrGenerator.insert("\t br i1 " + variableNew3 + ", label " +
					// 						"\%" + labelNew1 + ", label " + 
					// 						"\%" + labelNew2 + "\n");
					// llvmIrGenerator.insert(labelNew1 + ":\n");

					// llvmIrGenerator.labelGenerator.pushFalseLabel(labelNew2);
				}
			} else if(atype == CONST_INTEGER && etype == INTEGER){
				// alloc for a
				variableNew = llvmIrGenerator.variableGenerator.getVariable();
				llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");

				// store to a
				int aVal = (int) $a.varInfo.getVal();
				llvmIrGenerator.insert("\t store i32 " + aVal + ", " +
											"i32* " + variableNew + "\n");

				// load a
				variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
				llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
										variableNew + "\n");

				// load e
				eVarIdxStr = (String) $e.varInfo.getVal();
				variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
				llvmIrGenerator.insert("\t " + variableNew3 + " = load i32, i32* " +
											eVarIdxStr + "\n");

				// compare
				String variableNew4 = llvmIrGenerator.variableGenerator.getVariable();
				$cmpVar = variableNew4;

				if(opt.equals(">")){
					llvmIrGenerator.insert("\t " + variableNew4 + " = icmp sgt i32 " +
											variableNew2 + ", " + variableNew3 + "\n");
				} else if(opt.equals("<")){
					llvmIrGenerator.insert("\t " + variableNew4 + " = icmp slt i32 " +
											variableNew2 + ", " + variableNew3 + "\n");
				} else if(opt.equals("<=")){
					llvmIrGenerator.insert("\t " + variableNew4 + " = icmp sle i32 " +
											variableNew2 + ", " + variableNew3 + "\n");
				} else if(opt.equals(">=")){
					llvmIrGenerator.insert("\t " + variableNew4 + " = icmp sge i32 " +
											variableNew2 + ", " + variableNew3 + "\n");
				} else if(opt.equals("!=")){
					llvmIrGenerator.insert("\t " + variableNew4 + " = icmp ne i32 " +
											variableNew2 + ", " + variableNew3 + "\n");

				} else if(opt.equals("==")){
					llvmIrGenerator.insert("\t " + variableNew4 + " = icmp eq i32 " +
											variableNew2 + ", " + variableNew3 + "\n");
				}

				labelNew1 = llvmIrGenerator.labelGenerator.getLabel();
				labelNew2 = llvmIrGenerator.labelGenerator.getLabel();

				$trueLabel = labelNew1;
				$falseLabel = labelNew2;
				// llvmIrGenerator.insert("\t br i1 " + variableNew4 + ", label " +
				// 						"\%" + labelNew1 + ", label " + 
				// 						"\%" + labelNew2 + "\n");
				// llvmIrGenerator.insert(labelNew1 + ":\n");

				// llvmIrGenerator.labelGenerator.pushFalseLabel(labelNew2);
			} else if(atype == INTEGER && etype == CONST_INTEGER){
				// load a
				aVarIdxStr = (String) $a.varInfo.getVal();
				variableNew = llvmIrGenerator.variableGenerator.getVariable();
				llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
											aVarIdxStr + "\n");

				// alloc for e
				variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
				llvmIrGenerator.insert("\t " + variableNew1 + " = alloca i32\n");

				// store to e
				int eVal = (int) $e.varInfo.getVal();
				llvmIrGenerator.insert("\t store i32 " + eVal + ", " +
											"i32* " + variableNew1 + "\n");

				// load e
				variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
				llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
										variableNew1 + "\n");

				variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
				$cmpVar = variableNew3;

				// compare
				if(opt.equals(">")){
					llvmIrGenerator.insert("\t " + variableNew3 + " = icmp sgt i32 " +
											variableNew + ", " + variableNew2 + "\n");
				} else if(opt.equals("<")){
					llvmIrGenerator.insert("\t " + variableNew3 + " = icmp slt i32 " +
											variableNew + ", " + variableNew2 + "\n");
				} else if(opt.equals("<=")){
					llvmIrGenerator.insert("\t " + variableNew3 + " = icmp sle i32 " +
											variableNew + ", " + variableNew2 + "\n");
				} else if(opt.equals(">=")){
					llvmIrGenerator.insert("\t " + variableNew3 + " = icmp sge i32 " +
											variableNew + ", " + variableNew2 + "\n");
				} else if(opt.equals("!=")){
					llvmIrGenerator.insert("\t " + variableNew3 + " = icmp ne i32 " +
											variableNew + ", " + variableNew2 + "\n");

				} else if(opt.equals("==")){
					llvmIrGenerator.insert("\t " + variableNew3 + " = icmp eq i32 " +
											variableNew + ", " + variableNew2 + "\n");
				}

				labelNew1 = llvmIrGenerator.labelGenerator.getLabel();
				labelNew2 = llvmIrGenerator.labelGenerator.getLabel();

				$trueLabel = labelNew1;
				$falseLabel = labelNew2;
				// llvmIrGenerator.insert("\t br i1 " + variableNew3 + ", label " +
				// 						"\%" + labelNew1 + ", label " + 
				// 						"\%" + labelNew2 + "\n");
				// llvmIrGenerator.insert(labelNew1 + ":\n");

				// llvmIrGenerator.labelGenerator.pushFalseLabel(labelNew2);
			} else { // type error
				System.out.println("invalid type"); // fixme: show precise type to user

			}

			$valid = false;
		})*
		//| ID expr (CONDITIONAL_OP expression)*
		| assignment_expression (CONDITIONAL_OP expression)*;
expr	:	(COMPARE_OP | CONDITIONAL_OP ) expression ;


assignment_expression:  ID  assign_expr | (PP_OP | MM_OP)  normal_declarator (',' expression)* ;
assign_expr
	:	(PP_OP | MM_OP)(',' expression)* ;//| assign_op  expression(',' expression)* ;//  left factoring

arith_expression
returns [VarInfo varInfo, Boolean hasMultipleArith]
@init{
	int atype = ERR;
	int btype = ERR;
	int ires = 0;
	double dres = 0.0;
    String variableIdxStr;
	VarInfo info = new VarInfo();
	VarInfo ainfo = new VarInfo();
	VarInfo binfo = new VarInfo();
	Boolean hasMultipleArith = false; // true: e.g., b = (a + 3+ ...), false: b = a 
}
				: a = multiply_expression
					{
                        $varInfo = $a.varInfo;
						ainfo = $a.varInfo;
						atype = ainfo.getType();

						if($a.hasMultipleMul)
							hasMultipleArith = true;
					}
					(
						(
							(ADD_OP)=>(ADD_OP b = multiply_expression)
							{
								hasMultipleArith = true;
								if($b.hasMultipleMul)
									hasMultipleArith = true;

								binfo = $b.varInfo;

								atype = ainfo.getType();
								btype = binfo.getType();

								if(atype == btype){
									if(atype == INTEGER){
										// load twice and add

										// System.out.println("INTEGER INTEGER");

										String aVarIdxStr = (String) ainfo.getVal();
										String bVarIdxStr = (String) binfo.getVal();

										if(!ainfo.getIsLoad()){
											variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																		aVarIdxStr + "\n");

											if(ainfo.getIsNeg()){ // check if a is negative
												String tmp = llvmIrGenerator.variableGenerator.getVariable();
												llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																			variableNew1 + "\n");
												variableNew1 = tmp;
											}

											ainfo.setIsLoad(true);
											// System.out.println("a is not loaded");
										} else {
											variableNew1 = aVarIdxStr;
										}

										if(!binfo.getIsLoad()){
											variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
																		bVarIdxStr + "\n");

											if(binfo.getIsNeg()){ // check if a is negative
												String tmp = llvmIrGenerator.variableGenerator.getVariable();
												llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																			variableNew2 + "\n");
												variableNew2 = tmp;
											}

											binfo.setIsLoad(true);
											// System.out.println("b is not loaded");
										} else {
											variableNew2 = bVarIdxStr;
										}

										// variableNew1 = aVarIdxStr;
										// variableNew2 = bVarIdxStr;

										// add
										variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew3 + " = add nsw i32 " + 
																variableNew1 +", " + variableNew2 + "\n");

										ainfo.setType(INTEGER);
										ainfo.setVal(variableNew3);
										ainfo.setIsLoad(true);

									} else if(atype == CONST_INTEGER){
										// allocate, store and add 
										// System.out.println("CONST CONST");

										int aVal, bVal;
										// allocate new temp variable
										// allocate
										variableNew = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");

										// store
										aVal = (int) ainfo.getVal();
										if(ainfo.getIsNeg()){ // check if a is negative
											llvmIrGenerator.insert("\t store i32 " + "-" + aVal + ", " +
																		"i32* " + variableNew + "\n");
										} else {
											llvmIrGenerator.insert("\t store i32 " + aVal + ", " +
																		"i32* " + variableNew + "\n");
										}

										// load
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																variableNew + "\n");

										// add
										bVal = (int) binfo.getVal();
										variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

										if(binfo.getIsNeg()){ // check if b is negative
											llvmIrGenerator.insert("\t " + variableNew2 + " = add nsw i32 " + 
																	variableNew1 +", " + "-" + bVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew2 + " = add nsw i32 " + 
																	variableNew1 +", " + bVal + "\n");
										}

										ainfo.setType(INTEGER);
										ainfo.setVal(variableNew2);
										ainfo.setIsLoad(true);

									}
								} else if(atype == CONST_INTEGER && btype == INTEGER){ 
									// load, allocate, store, add
									// System.out.println("CONST INTEGER");

									// System.out.println("aType: " + info.getType() + ", " + " aVal: " + info.getVal());
									// System.out.println("bType: " + $b.varInfo.getType() + ", " + " bVal: " + $b.varInfo.getVal());

									// allocate new temp variable and load
									String bVarIdxStr = (String) binfo.getVal();
									int aVal = (int) ainfo.getVal();

									if(!binfo.getIsLoad()){
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																bVarIdxStr + "\n");

										if(binfo.getIsNeg()){ // check if b is negative
											String tmp = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																		variableNew1 + "\n");
											variableNew1 = tmp;
										}

										binfo.setIsLoad(true);

										// add
										variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

										if(ainfo.getIsNeg()){ // check if a is negative
											llvmIrGenerator.insert("\t " + variableNew2 + " = add nsw i32 " + 
																	variableNew1 +", " + "-" + aVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew2 + " = add nsw i32 " + 
																	variableNew1 +", " + aVal + "\n");
										}

										ainfo.setVal(variableNew2);
									} else {
										// add
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();

										if(ainfo.getIsNeg()){ // check if a is negative
											llvmIrGenerator.insert("\t " + variableNew1 + " = add nsw i32 " + 
																	bVarIdxStr +", " + "-" + aVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew1 + " = add nsw i32 " + 
																	bVarIdxStr +", " + aVal + "\n");
										}

										ainfo.setVal(variableNew1);
									}
									ainfo.setType(INTEGER);
									ainfo.setIsLoad(true);

									// System.out.println("variableNew2: " + variableNew2);
								} else if(atype == INTEGER && btype == CONST_INTEGER){

									// System.out.println("INTEGER CONST");

									// allocate new temp variable and load if is not load before
									String aVarIdxStr = (String) ainfo.getVal();
									int bVal = (int) binfo.getVal();

									if(!ainfo.getIsLoad()){
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																aVarIdxStr + "\n");

										if(ainfo.getIsNeg()){ // check if a is negative
											String tmp = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																		variableNew1 + "\n");
											variableNew1 = tmp;
										}

										// System.out.println("ainfo_var " + aVarIdxStr);
										// System.out.println("ainfo is load " + ainfo.getIsLoad());

										// add
										variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

										if(binfo.getIsNeg()){ // check if b is negative
											llvmIrGenerator.insert("\t " + variableNew2 + " = add nsw i32 " + 
																	variableNew1 +", " + "-" + bVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew2 + " = add nsw i32 " + 
																	variableNew1 +", " + bVal + "\n");
										}

										ainfo.setVal(variableNew2);
									} else { // need not to load a 
										// add
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										if(binfo.getIsNeg()){ // check if b is negative
											llvmIrGenerator.insert("\t " + variableNew1 + " = add nsw i32 " + 
																	aVarIdxStr +", " + "-" + bVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew1 + " = add nsw i32 " + 
																	aVarIdxStr +", " + bVal + "\n");
										}
										ainfo.setVal(variableNew1);
									}
									ainfo.setType(INTEGER);
									ainfo.setIsLoad(true);
								} else {
									System.out.println("variable " + $a.varInfo.getID() + 
														" and variable " + binfo.getID() + 
														" are invalid");
									System.exit(0);
								}
							}
						|
							(SUB_OP c = multiply_expression)
							{
								hasMultipleArith = true;
								
								binfo = $c.varInfo;

								atype = ainfo.getType();
								btype = binfo.getType();

								if(atype == btype){
									if(atype == INTEGER){
										// load twice and sub

										// System.out.println("INTEGER INTEGER");

										String aVarIdxStr = (String) ainfo.getVal();
										String bVarIdxStr = (String) binfo.getVal();

										if(!ainfo.getIsLoad()){
											variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																		aVarIdxStr + "\n");

											if(ainfo.getIsNeg()){ // check if a is negative
												String tmp = llvmIrGenerator.variableGenerator.getVariable();
												llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																			variableNew1 + "\n");
												variableNew1 = tmp;
											}

											ainfo.setIsLoad(true);
											// System.out.println("a is not loaded");
										} else {
											variableNew1 = aVarIdxStr;
										}

										if(!binfo.getIsLoad()){
											variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
																		bVarIdxStr + "\n");

											if(binfo.getIsNeg()){ // check if a is negative
												String tmp = llvmIrGenerator.variableGenerator.getVariable();
												llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																			variableNew2 + "\n");
												variableNew2 = tmp;
											}

											binfo.setIsLoad(true);
											// System.out.println("b is not loaded");
										} else {
											variableNew2 = bVarIdxStr;
										}

										// variableNew1 = aVarIdxStr;
										// variableNew2 = bVarIdxStr;

										// sub
										variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew3 + " = sub nsw i32 " + 
																variableNew1 +", " + variableNew2 + "\n");

										ainfo.setType(INTEGER);
										ainfo.setVal(variableNew3);
										ainfo.setIsLoad(true);

									} else if(atype == CONST_INTEGER){
										// allocate, store and sub 
										// System.out.println("CONST CONST");

										int aVal, bVal;
										// allocate new temp variable
										// allocate
										variableNew = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");

										// store
										aVal = (int) ainfo.getVal();
										if(ainfo.getIsNeg()){ // check if a is negative
											llvmIrGenerator.insert("\t store i32 " + "-" + aVal + ", " +
																		"i32* " + variableNew + "\n");
										} else {
											llvmIrGenerator.insert("\t store i32 " + aVal + ", " +
																		"i32* " + variableNew + "\n");
										}

										// load
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																variableNew + "\n");

										// sub
										bVal = (int) binfo.getVal();
										variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

										if(binfo.getIsNeg()){ // check if b is negative
											llvmIrGenerator.insert("\t " + variableNew2 + " = sub nsw i32 " + 
																	variableNew1 +", " + "-" + bVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew2 + " = sub nsw i32 " + 
																	variableNew1 +", " + bVal + "\n");
										}

										ainfo.setType(INTEGER);
										ainfo.setVal(variableNew2);
										ainfo.setIsLoad(true);

									}
								} else if(atype == CONST_INTEGER && btype == INTEGER){ 
									// load, allocate, store, sub
									// System.out.println("CONST INTEGER");

									// System.out.println("aType: " + info.getType() + ", " + " aVal: " + info.getVal());
									// System.out.println("bType: " + $b.varInfo.getType() + ", " + " bVal: " + $b.varInfo.getVal());

									// allocate new temp variable and load
									String bVarIdxStr = (String) binfo.getVal();
									int aVal = (int) ainfo.getVal();

									if(!binfo.getIsLoad()){
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																bVarIdxStr + "\n");

										if(binfo.getIsNeg()){ // check if b is negative
											String tmp = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																		variableNew1 + "\n");
											variableNew1 = tmp;
										}

										binfo.setIsLoad(true);

										// sub
										variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

										if(ainfo.getIsNeg()){ // check if a is negative
											llvmIrGenerator.insert("\t " + variableNew2 + " = sub nsw i32 " + 
																	variableNew1 +", " + "-" + aVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew2 + " = sub nsw i32 " + 
																	variableNew1 +", " + aVal + "\n");
										}

										ainfo.setVal(variableNew2);
									} else {
										// sub
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();

										if(ainfo.getIsNeg()){ // check if a is negative
											llvmIrGenerator.insert("\t " + variableNew1 + " = sub nsw i32 " + 
																	bVarIdxStr +", " + "-" + aVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew1 + " = sub nsw i32 " + 
																	bVarIdxStr +", " + aVal + "\n");
										}

										ainfo.setVal(variableNew1);
									}
									ainfo.setType(INTEGER);
									ainfo.setIsLoad(true);

									// System.out.println("variableNew2: " + variableNew2);
								} else if(atype == INTEGER && btype == CONST_INTEGER){

									// System.out.println("INTEGER CONST");

									// allocate new temp variable and load if is not load before
									String aVarIdxStr = (String) ainfo.getVal();
									int bVal = (int) binfo.getVal();

									if(!ainfo.getIsLoad()){
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
																aVarIdxStr + "\n");

										if(ainfo.getIsNeg()){ // check if a is negative
											String tmp = llvmIrGenerator.variableGenerator.getVariable();
											llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
																		variableNew1 + "\n");
											variableNew1 = tmp;
										}

										// System.out.println("ainfo_var " + aVarIdxStr);
										// System.out.println("ainfo is load " + ainfo.getIsLoad());

										// sub
										variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

										if(binfo.getIsNeg()){ // check if b is negative
											llvmIrGenerator.insert("\t " + variableNew2 + " = sub nsw i32 " + 
																	variableNew1 +", " + "-" + bVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew2 + " = sub nsw i32 " + 
																	variableNew1 +", " + bVal + "\n");
										}

										ainfo.setVal(variableNew2);
									} else { // need not to load a 
										// sub
										variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
										if(binfo.getIsNeg()){ // check if b is negative
											llvmIrGenerator.insert("\t " + variableNew1 + " = sub nsw i32 " + 
																	aVarIdxStr +", " + "-" + bVal + "\n");
										} else {
											llvmIrGenerator.insert("\t " + variableNew1 + " = sub nsw i32 " + 
																	aVarIdxStr +", " + bVal + "\n");
										}
										ainfo.setVal(variableNew1);
									}
									ainfo.setType(INTEGER);
									ainfo.setIsLoad(true);
								} else {
									System.out.println("variable " + $a.varInfo.getID() + 
														" and variable " + binfo.getID() + 
														" are invalid");
									System.exit(0);
								}

							}
						)*
					) {
						ainfo.setIsLoad(true);
						$varInfo = ainfo;

						$hasMultipleArith = hasMultipleArith;

						// if(!hasMultipleArith && $a.varInfo.getType() == INTEGER){ // load variable only
						// 	variableNew = llvmIrGenerator.variableGenerator.getVariable();
						// 	llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
						// 								(String) $a.varInfo.getVal() + "\n");
						// }
					}
             	;

mul_op: MUL_OP
		| DIV_OP
		| MOD_OP
		| RSHIFT_OP
		| LSHIFT_OP
		| BIT_OR_OP
		| BIT_AND_OP
		| BIT_XOR_OP
		;

multiply_expression
returns [VarInfo varInfo, Boolean hasMultipleMul]
@init{
	int ires = 0;
	double dres = 0.0;
	int atype = ERR;
	int btype = ERR;
    String variableIdxStr;
	VarInfo info = new VarInfo();
	VarInfo ainfo = new VarInfo();
	VarInfo binfo = new VarInfo();
	Boolean hasMultipleMul = false; // true: e.g., b = (a * 3 / ...), false: b = a 
}
		  : a = sign_expression
		  {
			$varInfo = $a.varInfo;
			ainfo = $a.varInfo;
			atype = ainfo.getType();
		  }
          (mul_op b = sign_expression {
				String op = $mul_op.text.toString();

				hasMultipleMul = true;

				binfo = $b.varInfo;

				atype = ainfo.getType();
				btype = binfo.getType();

				if(atype == btype){
					if(atype == INTEGER){
						// load twice and mul

						// System.out.println("INTEGER INTEGER");

						String aVarIdxStr = (String) ainfo.getVal();
						String bVarIdxStr = (String) binfo.getVal();

						if(!ainfo.getIsLoad()){
							variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
														aVarIdxStr + "\n");

							if(ainfo.getIsNeg()){ // check if a is negative
								String tmp = llvmIrGenerator.variableGenerator.getVariable();
								llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
															variableNew1 + "\n");
								variableNew1 = tmp;
							}

							ainfo.setIsLoad(true);
							// System.out.println("a is not loaded");
						} else {
							variableNew1 = aVarIdxStr;
						}

						if(!binfo.getIsLoad()){
							variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
														bVarIdxStr + "\n");

							if(binfo.getIsNeg()){ // check if a is negative
								String tmp = llvmIrGenerator.variableGenerator.getVariable();
								llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
															variableNew2 + "\n");
								variableNew2 = tmp;
							}

							binfo.setIsLoad(true);
							// System.out.println("b is not loaded");
						} else {
							variableNew2 = bVarIdxStr;
						}

						// variableNew1 = aVarIdxStr;
						// variableNew2 = bVarIdxStr;

						// mul
						variableNew3 = llvmIrGenerator.variableGenerator.getVariable();

						if(op.equals("*")){
							llvmIrGenerator.insert("\t " + variableNew3 + " = mul nsw i32 " + 
													variableNew1 +", " + variableNew2 + "\n");
						} else if(op.equals("/")){
							llvmIrGenerator.insert("\t " + variableNew3 + " = sdiv i32 " + 
													variableNew1 +", " + variableNew2 + "\n");
						}

						ainfo.setType(INTEGER);
						ainfo.setVal(variableNew3);
						ainfo.setIsLoad(true);

					} else if(atype == CONST_INTEGER){
						// allocate, store and mul 
						// System.out.println("CONST CONST");

						int aVal, bVal;
						// allocate new temp variable
						// allocate
						variableNew = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew + " = alloca i32\n");

						// store
						aVal = (int) ainfo.getVal();
						if(ainfo.getIsNeg()){ // check if a is negative
							llvmIrGenerator.insert("\t store i32 " + "-" + aVal + ", " +
														"i32* " + variableNew + "\n");
						} else {
							llvmIrGenerator.insert("\t store i32 " + aVal + ", " +
														"i32* " + variableNew + "\n");
						}

						// load
						variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
												variableNew + "\n");

						// mul
						bVal = (int) binfo.getVal();
						variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

						if(binfo.getIsNeg()){ // check if b is negative
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = mul nsw i32 " + 
														variableNew1 +", " + "-" + bVal + "\n");
							} else if(op.equals("/")){
								if(bVal == 0){
									System.out.println("Cannot divide by zero");
									System.exit(0);
								}
								llvmIrGenerator.insert("\t " + variableNew2 + " = sdiv i32 " + 
														variableNew1 +", " + "-" + bVal + "\n");
							}
						} else {
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = mul nsw i32 " + 
														variableNew1 +", " + bVal + "\n");
							} else if(op.equals("/")){
								if(bVal == 0){
									System.out.println("Cannot divide by zero");
									System.exit(0);
								}
								llvmIrGenerator.insert("\t " + variableNew2 + " = sdiv i32 " + 
														variableNew1 +", " + bVal + "\n");
							}
						}

						ainfo.setType(INTEGER);
						ainfo.setVal(variableNew2);
						ainfo.setIsLoad(true);

					}
				} else if(atype == CONST_INTEGER && btype == INTEGER){ 
					// load, allocate, store, mul
					// System.out.println("CONST INTEGER");

					// System.out.println("aType: " + info.getType() + ", " + " aVal: " + info.getVal());
					// System.out.println("bType: " + $b.varInfo.getType() + ", " + " bVal: " + $b.varInfo.getVal());

					// allocate new temp variable and load
					String bVarIdxStr = (String) binfo.getVal();
					int aVal = (int) ainfo.getVal();

					if(!binfo.getIsLoad()){
						variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
												bVarIdxStr + "\n");

						if(binfo.getIsNeg()){ // check if b is negative
							String tmp = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
														variableNew1 + "\n");
							variableNew1 = tmp;
						}

						binfo.setIsLoad(true);

						// mul
						variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

						if(ainfo.getIsNeg()){ // check if a is negative
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = mul nsw i32 " + 
														variableNew1 +", " + "-" + aVal + "\n");
							} else if(op.equals("/")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = sdiv i32 " + 
														variableNew1 +", " + "-" + aVal + "\n");
							}
						} else {
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = mul nsw i32 " + 
														variableNew1 +", " + aVal + "\n");
							} else if(op.equals("/")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = sdiv i32 " + 
														variableNew1 +", " + aVal + "\n");
							}
						}

						ainfo.setVal(variableNew2);
					} else {
						// mul
						variableNew1 = llvmIrGenerator.variableGenerator.getVariable();

						if(ainfo.getIsNeg()){ // check if a is negative
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = mul nsw i32 " + 
														bVarIdxStr +", " + "-" + aVal + "\n");
							} else if(op.equals("/")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = sdiv i32 " + 
														bVarIdxStr +", " + "-" + aVal + "\n");
							}
						} else {
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = mul nsw i32 " + 
														bVarIdxStr +", " + aVal + "\n");
							} else if(op.equals("/")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = div nsw i32 " + 
														bVarIdxStr +", " + aVal + "\n");
							}
						}

						ainfo.setVal(variableNew1);
					}
					ainfo.setType(INTEGER);
					ainfo.setIsLoad(true);

					// System.out.println("variableNew2: " + variableNew2);
				} else if(atype == INTEGER && btype == CONST_INTEGER){

					// System.out.println("INTEGER CONST");

					// allocate new temp variable and load if is not load before
					String aVarIdxStr = (String) ainfo.getVal();
					int bVal = (int) binfo.getVal();

					if(!ainfo.getIsLoad()){
						variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew1 + " = load i32, i32* " +
												aVarIdxStr + "\n");

						if(ainfo.getIsNeg()){ // check if a is negative
							String tmp = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + tmp + " = sub nsw i32 0, " +
														variableNew1 + "\n");
							variableNew1 = tmp;
						}

						// System.out.println("ainfo_var " + aVarIdxStr);
						// System.out.println("ainfo is load " + ainfo.getIsLoad());

						// mul
						variableNew2 = llvmIrGenerator.variableGenerator.getVariable();

						if(binfo.getIsNeg()){ // check if b is negative
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = mul nsw i32 " + 
														variableNew1 +", " + "-" + bVal + "\n");
							} else if(op.equals("/")){
								if(bVal == 0){
									System.out.println("Cannot divide by zero");
									System.exit(0);
								}
								llvmIrGenerator.insert("\t " + variableNew2 + " = sdiv i32 " + 
														variableNew1 +", " + "-" + bVal + "\n");
							}
						} else {
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew2 + " = mul nsw i32 " + 
														variableNew1 +", " + bVal + "\n");
							} else if(op.equals("/")){
								if(bVal == 0){
									System.out.println("Cannot divide by zero");
									System.exit(0);
								}
								llvmIrGenerator.insert("\t " + variableNew2 + " = sdiv i32 " + 
														variableNew1 +", " + bVal + "\n");
							}
						}

						ainfo.setVal(variableNew2);
					} else { // need not to load a 
						// mul
						variableNew1 = llvmIrGenerator.variableGenerator.getVariable();
						if(binfo.getIsNeg()){ // check if b is negative
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = mul nsw i32 " + 
														aVarIdxStr +", " + "-" + bVal + "\n");
							} else if(op.equals("/")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = sdiv i32 " + 
														aVarIdxStr +", " + "-" + bVal + "\n");
							}
						} else {
							if(op.equals("*")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = mul nsw i32 " + 
														aVarIdxStr +", " + bVal + "\n");
							} else if(op.equals("/")){
								llvmIrGenerator.insert("\t " + variableNew1 + " = sdiv i32 " + 
														aVarIdxStr +", " + bVal + "\n");
							}
						}
						ainfo.setVal(variableNew1);
					}
					ainfo.setType(INTEGER);
					ainfo.setIsLoad(true);
				} else {
					System.out.println("variable " + $a.varInfo.getID() + 
										" and variable " + binfo.getID() + 
										" are invalid");
					System.exit(0);
				}
			})* {
				// ainfo.setIsLoad(true);
				$varInfo = ainfo;

				$hasMultipleMul = hasMultipleMul;
			}
		  ;

sign_expression
returns [VarInfo varInfo]
@init{
	int itmp = 0;
	double dtmp = 0.0;
	VarInfo info = new VarInfo();
}
				: a = primary_expression
				{
					// info.setType($a.varInfo.getType());
	                // info.setVal($a.varInfo.getVal());
	                // info.setID($a.varInfo.getID());
	                // $varInfo = info;

					// $a.varInfo.setIsLoad(false);
					if(isBracketArith){
						$varInfo = $a.varInfo;
						isBracketArith = false;
					} else {
						info.setType($a.varInfo.getType());
						info.setVal($a.varInfo.getVal());
						info.setID($a.varInfo.getID());
						info.setArraySize($a.varInfo.getArraySize());
						$varInfo = info;
					}
				}
				| '-' b = primary_expression
				{
	                int type = $b.varInfo.getType();
					if(type == INTEGER || type == CONST_INTEGER){
						// itmp = (int) $b.varInfo.getVal();
						// if(itmp < 0){ // b already has '-' symbol from terminal, so two negatives make a positive
						//     $b.varInfo.setVal(Integer.parseInt(((Integer)(-itmp)).toString()));
						// } else {
						//     $b.varInfo.setVal(Integer.parseInt("-" + ((Integer)($b.varInfo.getVal())).toString()));
						// }

						if(isBracketArith){
							$b.varInfo.setIsNeg(true);
							$varInfo = $b.varInfo;
							isBracketArith = false;
						} else {
							info.setType($b.varInfo.getType());
							info.setVal($b.varInfo.getVal());
							info.setID($b.varInfo.getID());
							info.setArraySize($b.varInfo.getArraySize());
							info.setIsNeg(true);
							$varInfo = info;
						}
					} else if(type == DOUBLE){
						dtmp = (double) $b.varInfo.getVal();
						if(dtmp < 0.0){ // b already has '-' symbol from terminal, so two negatives make a positive
						    $b.varInfo.setVal(Double.parseDouble(((Double)(-dtmp)).toString()));
						} else {
						    $b.varInfo.setVal(Double.parseDouble("-" + ((Double)($b.varInfo.getVal())).toString()));
						}
					}

	                // $varInfo = $b.varInfo;
				}
				;

primary_expression
returns [VarInfo varInfo]
@init {
    VarInfo info = new VarInfo();
}
				: ID {
					VarInfo v = symtab.get($ID.text);
					if(v != null){
	                    $varInfo = v;
					} else {
						System.out.println("Undefined variable: " + $ID.text);
						System.exit(0);
					}
				}
				| constant
				{
					try { // integer
					    info.setType(CONST_INTEGER);
					    info.setVal(Integer.parseInt($constant.text));
					} catch(NumberFormatException excep){ // character
						// System.out.println($constant.text.toString());
					    info.setType(CHARACTER);
						info.setVal((int) $constant.text.toString().charAt(1));
					}
					info.setIsLoad(false);
                    $varInfo = info;

					// System.out.println("prima:" + $constant.text.toString());
				}
				| '(' e=expression ')'
				{
                    $varInfo = $e.varInfo;
					isBracketArith = true;
				}
				;

statement_list: statement;

	/*declarator_type
	: VOID_TYPE | type decl | decl;  // void type is special type which do not require an ID

decl	:	normal_declarator | (pointer_declarator)* normal_declarator;


declarator
	: declarator_type (assign_op initializer)?  ';'?
	;*/

statement:
    //(ID COLON)=>label_statement |
    declarator_list |
    expression_statement |
    conditional_statement |
    jump_statement |
    loop_statement|
    function_call_statement;

label_statement: ID COLON (statement)*
					{if (TRACEON) System.out.println("\nlabel statement:\n" + $label_statement.text.toString());}
			   ;

expression_statement: ';' |
                      expression ';' ;

if_statement
returns [String fLabel]
@init{
	String trueLabel = null;
	String falseLabel = null;
	String cmpVar = null;
}
	: IF_TYPE '(' e=expression ')' {
		valid = $e.valid;

		trueLabel = $e.trueLabel;
		falseLabel = $e.falseLabel;
		cmpVar = $e.cmpVar;

		$fLabel = falseLabel;
		ifFalseLabel = falseLabel;

		llvmIrGenerator.insert("\t br i1 " + cmpVar + ", label " +
								"\%" + trueLabel + ", label " + 
								"\%" + falseLabel + "\n");
		llvmIrGenerator.insert(trueLabel + ":\n");

		endLabelList.add(falseLabel);
		hasElseIfOrElseList.add(false);
	} '{' (statement)* '}' {
		if(valid)
			conditionalDone = true;

	}
	;

else_if_statement
@init {
	String endLabel = null;

	String trueLabel = null;
	String falseLabel = null;
	String cmpVar = null;
}
	:
	  ELSE_TYPE IF_TYPE {
		elseifCnt += 1;
		hasElseIfOrElseList.set(hasElseIfOrElseList.size() - 1, true);
		endLabel = llvmIrGenerator.labelGenerator.getLabel();
		// System.out.println("endLabel: " + endLabel);

		if(elseifCnt == 1){
			endLabelList.set(endLabelList.size() - 1, endLabel);
		} else {
			endLabelList.add(endLabel);
		}

		if(ifFalseLabel != null){
			if(!(has_break || has_continue)){
				llvmIrGenerator.insert("\t br label \%" + endLabel + "\n");
			} else { // break and continue statement will take care of jump
				has_break = false;
				has_continue = false;
			}

			//llvmIrGenerator.insert("\t br label \%" + endLabel + "\n");
			llvmIrGenerator.insert(ifFalseLabel + ":\n");
			ifFalseLabel = null;
		}
	  } '(' e=expression ')' {
		valid = $e.valid;

		trueLabel = $e.trueLabel;
		falseLabel = $e.falseLabel;
		cmpVar = $e.cmpVar;

		llvmIrGenerator.insert("\t br i1 " + cmpVar + ", label " +
								"\%" + trueLabel + ", label " + 
								"\%" + falseLabel + "\n");
		llvmIrGenerator.insert(trueLabel + ":\n");
	} '{' (statement)* '}' {
		if(valid)
			conditionalDone = true;

		endLabel = endLabelList.get(endLabelList.size() - 1);
		//llvmIrGenerator.insert("\t br label \%" + endLabel + "\n");

		if(!(has_break || has_continue)){
			llvmIrGenerator.insert("\t br label \%" + endLabel + "\n");
		} else { // break and continue statement will take care of jump
			has_break = false;
			has_continue = false;
		}

		llvmIrGenerator.insert(falseLabel + ":\n");
	}
	;

else_statement
	: ELSE_TYPE {
		hasElseIfOrElseList.set(hasElseIfOrElseList.size() - 1, true);

		if(ifFalseLabel != null){
			String endLabel = llvmIrGenerator.labelGenerator.getLabel();
			endLabelList.set(endLabelList.size() - 1, endLabel);
			//llvmIrGenerator.insert("\t br label \%" + endLabel + "\n");

			if(!(has_break || has_continue)){
				llvmIrGenerator.insert("\t br label \%" + endLabel + "\n");
			} else { // break and continue statement will take care of jump
				has_break = false;
				has_continue = false;
			}

			llvmIrGenerator.insert(ifFalseLabel + ":\n");
			ifFalseLabel = null;
		}

		if(!valid) // previous if_statement and if_else_statement do not valid
			valid = true;
	} '{' (statement)* '}' {

	}
	;

conditional_statement: {reachConditionalStatement = true;}
						i=if_statement (else_if_statement)* (else_statement)?
						{
							String falseLabel;
							String tmpLabel;
							String tmpLabelNext;
							Boolean hasElseIfOrElse = hasElseIfOrElseList.get(hasElseIfOrElseList.size() - 1);

							if(hasElseIfOrElse){ // jump to global label
								falseLabel = endLabelList.get(endLabelList.size() - 1);
                                //llvmIrGenerator.insert("\t br label \%" + falseLabel + "\n");
								if(!(has_break || has_continue)){
									llvmIrGenerator.insert("\t br label \%" + falseLabel + "\n");
								} else { // break and continue statement will take care of jump
									has_break = false;
									has_continue = false;
								}

								// chain all global label
								for(int j = 0; j < endLabelList.size() - 1; j++){ 
									tmpLabel = endLabelList.get(j);
									tmpLabelNext = endLabelList.get(j + 1);
									llvmIrGenerator.insert(tmpLabel + ":\n");
									llvmIrGenerator.insert("\t br label \%" + tmpLabelNext + "\n");
								}

							} else { // jump to false label
								falseLabel = $i.fLabel;

								if(!(has_break || has_continue)){
									llvmIrGenerator.insert("\t br label \%" + falseLabel + "\n");
								} else { // break and continue statement will take care of jump
									has_break = false;
									has_continue = false;
								}
							}	
							llvmIrGenerator.insert(falseLabel + ":\n");

							elseifCnt = 0;
							endLabelList.clear();
							hasElseIfOrElseList.clear();

							conditionalDone = false;
							reachConditionalStatement = false;
							if (TRACEON) System.out.println("\nif else statement:\n" + $conditional_statement.text.toString());
						}
					 ;

// printf_function_argument
// 	:	LITERAL (',' (expression | '-' expression |'&' expression ))*
// 	;

addrOf
returns [Boolean hasAddrOf]
	: r='&'? {
		if($r != null)
			hasAddrOf = true;
		else
			hasAddrOf = false;
	};

printf_function_argument
@init {
	ArrayList<String> paramList = new ArrayList<>();
	ArrayList<Boolean> isParamAddrOfList = new ArrayList<>();
	ArrayList<String> arrayIdxList = new ArrayList<>();
	ArrayList<String> loadVariableList = new ArrayList<>();
	String variableNew = null;
	VarInfo varinfo = null;
	StringBuilder printfStr = new StringBuilder();
	int type = ERR;
	Boolean isArray = false;
	String arrayIdx = "0";
	String loadVariable = null;
}
	:	l=LITERAL
		(',' r=addrOf n=normal_declarator
		{
			isArray = false;

			if($r.hasAddrOf)
				isParamAddrOfList.add(true);
			else
				isParamAddrOfList.add(false);

			String tmpParam = $n.text.toString();
			String realParam = "";

			for(int i = 0; i < tmpParam.length(); i++){
				if(tmpParam.charAt(i) == '['){
					int closeBracketIdx = tmpParam.indexOf(']');
					arrayIdxList.add(tmpParam.substring(i + 1, closeBracketIdx));
					if($n.loadVariable != null){
						loadVariableList.add($n.loadVariable);
					} else {
						loadVariableList.add(tmpParam.substring(i + 1, closeBracketIdx));
					}
					isArray = true;
					break;
				}
				realParam += tmpParam.charAt(i);
			}

			if(!isArray) {
				arrayIdxList.add("padding");
				loadVariableList.add("padding");
			}

			paramList.add(realParam);
		})* {
			/* declare LITERAL as array in LLVM IR */
			String variableNewGlobal = llvmIrGenerator.variableGenerator.getGlobalVariable(".str");

			str = $l.text.toString();
			str = str.substring(1, str.length() - 1); // remove double quote
			String asciiStr = llvmIrGenerator.asciiTransform(str);
			int strlen = llvmIrGenerator.asciiStrLen(asciiStr);

			// declare global string
			llvmIrGenerator.insertFront("@" + variableNewGlobal + " = private unnamed_addr constant [" + strlen + " x i8] c" + "\"" + asciiStr + "\"\n");

			// call printf function
			printfStr.append(" = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" + strlen + " x i8], [" + strlen + " x i8]* @" + variableNewGlobal + ", i32 0, i32 0)");

			for(int i = 0; i < paramList.size(); i++){
				// load param

				// System.out.println("------------------");
				// System.out.println("var: " + paramList.get(i));
				// System.out.println("------------------");
				varinfo = symtab.get(paramList.get(i));
				if(varinfo == null){
					System.out.println("Undefined variable: " + paramList.get(i));
					System.exit(0);
				}

				type = varinfo.getType();
				if(type == INTEGER){
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
												(String) varinfo.getVal() + "\n");
					printfStr.append(", i32 " + variableNew);
				} else if(type == CHARACTER){
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = load i8, i8* " +
												(String) varinfo.getVal() + "\n");
					
					variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew2 + " = sext i8 " + variableNew +
												" to i32\n");

					printfStr.append(", i32 " + variableNew2);
				} else if (type == CHARACTER_ARRAY){
					if(arrayIdxList.size() != 0)
						arrayIdx = arrayIdxList.get(i).equals("padding") ? "0" : arrayIdxList.get(i);

						// System.out.println("----------------------");
						// System.out.println("arayIdx " + loadVariableList.get(i));
						// System.out.println("----------------------");

						if(loadVariableList.get(i).equals("padding")){ // access whole array of character
							variableNew = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + varinfo.getArraySize() + " x i8], " +  
										"[" + varinfo.getArraySize() +  " x i8]* " + (String) varinfo.getVal() + ", i8 0, i32 " + arrayIdx + "\n");
						} else { // accessment to a single character in a array of character
							try { // arrayIdx is integer
								int tmp = Integer.parseInt(arrayIdx);
								variableNew = llvmIrGenerator.variableGenerator.getVariable();
								llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + varinfo.getArraySize() + " x i8], " +  
											"[" + varinfo.getArraySize() +  " x i8]* " + (String) varinfo.getVal() + ", i32 0, i32 " + arrayIdx + "\n");
							} catch(NumberFormatException e){ // arrayIdx is variable
								if(loadVariableList.get(i).equals("padding"))
									variableNew = llvmIrGenerator.variableGenerator.getPrevVariable();
								else
									variableNew = loadVariableList.get(i);
							}
						}

					// printfStr.append(", i8* " + variableNew);
					if(isParamAddrOfList.get(i) || arrayIdx.equals("0")){ // address of
						printfStr.append(", i8* " + variableNew);
					} else {
						// need to load first

						String variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew2 + " = load i8, i8* " +
													variableNew + "\n");

						String variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew3 + " = sext i8 " + variableNew2 + 
												" to i32\n");

						printfStr.append(", i32 " + variableNew3);
					}
				} else if(type == INTEGER_ARRAY){
					if(arrayIdxList.size() != 0)
						arrayIdx = arrayIdxList.get(i).equals("padding") ? "0" : arrayIdxList.get(i);

						try { // arrayIdx is integer
							int tmp = Integer.parseInt(arrayIdx);
							variableNew = llvmIrGenerator.variableGenerator.getVariable();
							llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + varinfo.getArraySize() + " x i32], " +  
										"[" + varinfo.getArraySize() +  " x i32]* " + (String) varinfo.getVal() + ", i32 0, i32 " + arrayIdx + "\n");
						} catch(NumberFormatException e){ // arrayIdx is variable
							if(loadVariableList.get(i).equals("padding"))
								variableNew = llvmIrGenerator.variableGenerator.getPrevVariable();
							else
								variableNew = loadVariableList.get(i);
						}
								
					if(isParamAddrOfList.get(i)){ // address of
						printfStr.append(", i32* " + variableNew);
					} else {
						// need to load first

						String variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
						llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
													variableNew + "\n");

						printfStr.append(", i32 " + variableNew2);
					}
				}
			}
			printfStr.append(")\n");

			variableNew = llvmIrGenerator.variableGenerator.getVariable();
			printfStr.insert(0, "\t " + variableNew);

			llvmIrGenerator.insert(printfStr.toString());
		}
	;

scanf_function_argument
@init {
	ArrayList<String> paramList = new ArrayList<>();
	ArrayList<Boolean> isParamAddrOfList = new ArrayList<>();
	ArrayList<String> arrayIdxList = new ArrayList<>();
	ArrayList<String> loadVariableList = new ArrayList<>();
	String variableNew = null;
	VarInfo varinfo = new VarInfo();
	StringBuilder scanfStr = new StringBuilder();
	int type = ERR;
	Boolean isArray = false;
	String arrayIdx = "";
}
	:	l=LITERAL
	(',' r=addrOf n=normal_declarator {

		isArray = false;
		if($r.hasAddrOf)
			isParamAddrOfList.add(true);
		else
			isParamAddrOfList.add(false);

		String tmpParam = $n.text.toString();
		String realParam = "";

		for(int i = 0; i < tmpParam.length(); i++){
			if(tmpParam.charAt(i) == '['){
				int closeBracketIdx = tmpParam.indexOf(']');
				arrayIdxList.add(tmpParam.substring(i + 1, closeBracketIdx));
				if($n.loadVariable != null){
					loadVariableList.add($n.loadVariable);
				} else {
					loadVariableList.add(tmpParam.substring(i + 1, closeBracketIdx));
				}
				isArray = true;
				break;
			}
			realParam += tmpParam.charAt(i);
		}

		if(!isArray){
			arrayIdxList.add("padding");
			loadVariableList.add("padding");
		}

		paramList.add(realParam);
	})* {
		/* declare LITERAL as array in LLVM IR */
		String variableNewGlobal = llvmIrGenerator.variableGenerator.getGlobalVariable(".str");

		str = $l.text.toString();
		str = str.substring(1, str.length() - 1); // remove double quote
		String asciiStr = llvmIrGenerator.asciiTransform(str);
		int strlen = llvmIrGenerator.asciiStrLen(asciiStr);

		// declare global string
		llvmIrGenerator.insertFront("@" + variableNewGlobal + " = private unnamed_addr constant [" + strlen + " x i8] c" + "\"" + asciiStr + "\"\n");

		// call scanf function
		scanfStr.append("= call i32 (i8*, ...) @__isoc99_scanf(i8* getelementptr inbounds ([" + strlen + " x i8], [" + strlen + " x i8]* @" + variableNewGlobal + ", i32 0, i32 0)");

		for(int i = 0; i < paramList.size(); i++){
			// load param
			varinfo = symtab.get(paramList.get(i));
			if(varinfo == null){
				System.out.println("Undefined variable: " + paramList.get(i));
				System.exit(0);
			}

			type = varinfo.getType();
			if(type == INTEGER){
				// llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
				// 							(String) varinfo.getVal() + "\n");
				scanfStr.append(", i32* " + (String) varinfo.getVal());
			} else if(type == CHARACTER){
				scanfStr.append(", i8* " + (String) varinfo.getVal());
			} else if (type == CHARACTER_ARRAY){
				arrayIdx = arrayIdxList.get(i).equals("padding") ? "0" : arrayIdxList.get(i);
				
				try { // arrayIdx is integer
					int tmp = Integer.parseInt(arrayIdx);
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + varinfo.getArraySize() + " x i8], " +  
								"[" + varinfo.getArraySize() +  " x i8]* " + (String) varinfo.getVal() + ", i32 0, i32 " + arrayIdx + "\n");
				} catch(NumberFormatException e){ // arrayIdx is variable
					if(loadVariableList.get(i).equals("padding"))
						variableNew = llvmIrGenerator.variableGenerator.getPrevVariable();
					else 
						variableNew = loadVariableList.get(i);
				}

				scanfStr.append(", i8* " + variableNew);

				// if(isParamAddrOfList.get(i)){ // address of
				// 	// llvmIrGenerator.insert(" i8* " + varinfo.getArraySize());
				// } else {
				// 	scanfStr.append(", i8 " + variableNew);
				// 	// llvmIrGenerator.insert(" i8 " + varinfo.getArraySize());
				// }
			} else if (type == INTEGER_ARRAY){
				arrayIdx = arrayIdxList.get(i).equals("padding") ? "0" : arrayIdxList.get(i);

				try { // arrayIdx is integer
					int tmp = Integer.parseInt(arrayIdx);
					variableNew = llvmIrGenerator.variableGenerator.getVariable();
					llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + varinfo.getArraySize() + " x i32], " +  
								"[" + varinfo.getArraySize() +  " x i32]* " + (String) varinfo.getVal() + ", i32 0, i32 " + arrayIdx + "\n");
				} catch(NumberFormatException e){ // arrayIdx is variable
					if(loadVariableList.get(i).equals("padding"))
						variableNew = llvmIrGenerator.variableGenerator.getPrevVariable();
					else 
						variableNew = loadVariableList.get(i);
				}

				if(isParamAddrOfList.get(i)){ // address of
					// String variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
					// llvmIrGenerator.insert("\t " + variableNew2 + " = load i32, i32* " +
					// 							variableNew + "\n");

					scanfStr.append(", i32* " + variableNew);
				} else {
					scanfStr.append(", i32 " + variableNew);
				}
			} 
		}
		scanfStr.append(")\n");

		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		scanfStr.insert(0, "\t " + variableNew);

		llvmIrGenerator.insert(scanfStr.toString());
	}
	;

strlen_function_argument
	: e=expression 
	{
		VarInfo varinfo = $e.varInfo;
		String variableNew = llvmIrGenerator.variableGenerator.getVariable();

		// calculate the offset of buffer
		llvmIrGenerator.insert("\t " + variableNew + " = getelementptr inbounds [" + varinfo.getArraySize() + " x i8], " +  
					"[" + varinfo.getArraySize() +  " x i8]* " + (String) varinfo.getVal() + ", i32 0, i32 0\n");

		// call strlen function
		String variableNew2 = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew2 + " = call i64 @strlen(i8* " + variableNew + ")\n");

		// truncate from 64 bit to 32 bit
		String variableNew3 = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew3 + " = trunc i64 " + variableNew2 + " to i32\n");
	}
	;

malloc_function_argument
	:	expression
	;

free_function_argument
	:	expression
	;

strcpy_function_argument
	:	expression ',' expression
	;

open_function_argument
returns [String variableNew]
@init {
	int mode = -1;
}
	:	l=LITERAL ',' f=expression (',' m=expression { mode = (int) $m.varInfo.getVal(); } )?
	{
		String filename = $l.text.toString();
		filename = filename.substring(1, filename.length() - 1); // remove quote
		int flag = (int) $f.varInfo.getVal();

		String variableNewGlobal = llvmIrGenerator.variableGenerator.getGlobalVariable(".str");

		int filenameLen = filename.length() + 1;
		String asciiStr = llvmIrGenerator.asciiTransform(filename);

		// declare global string
		llvmIrGenerator.insertFront("@" + variableNewGlobal + " = private unnamed_addr constant [" + filenameLen + " x i8] c" + "\"" + asciiStr + "\"\n");

		// call open function
		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		if(mode != -1){ // has mode
			llvmIrGenerator.insert("\t " + variableNew + " = call i32 (i8*, i32, ...) @open(i8* getelementptr inbounds ([" + filenameLen + " x i8], [" + filenameLen + " x i8]* @" + 
									variableNewGlobal + ", i32 0, i32 0)" + ", i32 " + flag + ", i32 " + mode + ")\n");
		} else {
			llvmIrGenerator.insert("\t " + variableNew + " = call i32 (i8*, i32, ...) @open(i8* getelementptr inbounds ([" + filenameLen + " x i8], [" + filenameLen + " x i8]* @" + 
									variableNewGlobal + ", i32 0, i32 0)" + ", i32 " + flag + ")\n");
		}

		$variableNew = variableNew;
	}
	;

read_function_argument
returns [String variableNew]
@init {
	String fd = null;
	String buf = null;
	int bufSize = -1;
	String bufOffset = null;
	// int readSize = -1;
	String readSize = null;
}
	:	e=expression ',' b=expression ',' cnt=expression
	{
		// load fd
		fd = (String) $e.varInfo.getVal();
		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
									fd + "\n");
		fd = variableNew;

		// calculate the buffer offset
		buf = (String) $b.varInfo.getVal();
		bufSize = $b.varInfo.getArraySize();
		bufOffset = "getelementptr inbounds [" + bufSize + " x i8], " +  
					"[" + bufSize +  " x i8]* " + buf + ", i32 0, i32 0";
		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew + " = " + bufOffset + "\n");
		buf = variableNew;

		// get the read size
		if($cnt.varInfo.getType() == CONST_INTEGER){
			readSize = Integer.toString((int) $cnt.varInfo.getVal());
		} else { // variable
			// load to use
			readSize = (String) $cnt.varInfo.getVal();
			variableNew = llvmIrGenerator.variableGenerator.getVariable();
			llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
										readSize + "\n");
			readSize = variableNew;
		}

		// call read function 
		variableNew = llvmIrGenerator.variableGenerator.getVariable();

		llvmIrGenerator.insert("\t " + variableNew + " = call i32 (i32, i8*, i32, ...) bitcast (i32 (...)* @read to i32 (i32, i8*, i32, ...)*)(i32 " + 
								fd + ", i8* " + buf + ", i32 " + readSize + ")\n");

		$variableNew = variableNew;
	}
	;

write_function_argument
returns [String variableNew]
@init {
	String fd = null;
	String buf = null;
	int bufSize = -1;
	String bufOffset = null;
	// int writeSize = -1;
	String writeSize = null;
}
	:	e=expression ',' b=expression ',' cnt=expression 
	{
		// load fd
		fd = (String) $e.varInfo.getVal();
		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
									fd + "\n");
		fd = variableNew;

		// calculate the buffer offset
		buf = (String) $b.varInfo.getVal();
		bufSize = $b.varInfo.getArraySize();
		bufOffset = "getelementptr inbounds [" + bufSize + " x i8], " +  
					"[" + bufSize +  " x i8]* " + buf + ", i32 0, i32 0";
		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew + " = " + bufOffset + "\n");
		buf = variableNew;

		// get the write size
		if($cnt.varInfo.getType() == CONST_INTEGER){
			writeSize = Integer.toString((int) $cnt.varInfo.getVal());
		} else { // variable
			// load to use
			writeSize = (String) $cnt.varInfo.getVal();
			variableNew = llvmIrGenerator.variableGenerator.getVariable();
			llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
										writeSize + "\n");
			writeSize = variableNew;
		}

		// call write function 
		variableNew = llvmIrGenerator.variableGenerator.getVariable();

		llvmIrGenerator.insert("\t " + variableNew + " = call i32 (i32, i8*, i32, ...) bitcast (i32 (...)* @write to i32 (i32, i8*, i32, ...)*)(i32 " + 
								fd + ", i8* " + buf + ", i32 " + writeSize + ")\n");

		$variableNew = variableNew;
	}
	;

close_function_argument
returns [String variableNew]
@init {
	String fd = null;
	String buf = null;
	int bufSize = -1;
	String bufOffset = null;
	int readSize = -1;
}
	:	e=expression 
	{
		// load fd
		fd = (String) $e.varInfo.getVal();
		variableNew = llvmIrGenerator.variableGenerator.getVariable();
		llvmIrGenerator.insert("\t " + variableNew + " = load i32, i32* " +
									fd + "\n");
		fd = variableNew;

		// call close function 
		variableNew = llvmIrGenerator.variableGenerator.getVariable();

		llvmIrGenerator.insert("\t " + variableNew + " = call i32 (i32, ...) bitcast (i32 (...)* @close to i32 (i32, ...)*)(i32 " + fd + ")\n");

		$variableNew = variableNew;
	}
	;

exit_function_argument
	:	expression
	;

function_call_statement
returns [String variableNew]
	:	(PRINTF_FUNC '(' printf_function_argument ')'
	|	SCANF_FUNC '(' scanf_function_argument ')'
	|	STRLEN_FUNC '(' strlen_function_argument ')'
	|	MALLOC_FUNC '(' malloc_function_argument ')'
	|	FREE_FUNC '(' free_function_argument ')'
	|	STRCPY_FUNC '(' strcpy_function_argument ')'
	|	OPEN_FUNC '(' ret=open_function_argument ')' { $variableNew = $ret.variableNew; }
	|	READ_FUNC '(' read_function_argument ')'
	|	WRITE_FUNC '(' write_function_argument ')'
	|	CLOSE_FUNC '(' close_function_argument ')'
	|	EXIT_FUNC '(' exit_function_argument ')' ) ';'
	{if (TRACEON) System.out.println("\nfunction call statement:\n" + $function_call_statement.text.toString());}
	;

loop_statement
@init {
	String loopLabel = null;
	String falseLabel = null;

	String trueLabel = null;
	String cmpVar = null;
}
				: 
				(WHILE_TYPE { 
					// first jump
					loopLabel = llvmIrGenerator.labelGenerator.getLabel();
					llvmIrGenerator.insert("\t br label \%" + loopLabel + "\n");
					llvmIrGenerator.insert(loopLabel + ":\n");

					while_init_label = loopLabel; // for continue statement
				} '(' e=expression {
					trueLabel = $e.trueLabel;
					falseLabel = $e.falseLabel;
					cmpVar = $e.cmpVar;
					llvmIrGenerator.insert("\t br i1 " + cmpVar + ", label " +
											"\%" + trueLabel + ", label " + 
											"\%" + falseLabel + "\n");
					llvmIrGenerator.insert(trueLabel + ":\n");

					while_false_label = falseLabel; // for break statement				
				} ')' '{' (statement)* '}' {
					// check condition again
					llvmIrGenerator.insert("\t br label \%" + loopLabel + "\n");

					// falseLabel = llvmIrGenerator.labelGenerator.popFalseLabel();
					llvmIrGenerator.insert(falseLabel + ":\n");
				}
			  | DO_TYPE '{' (statement)* '}' WHILE_TYPE '(' expression ')' ';'
			  | FOR_TYPE '(' statement expression_statement expression? ')' '{' (statement)* '}' )
			  {if (TRACEON) System.out.println("\nloop statement:\n" + $loop_statement.text.toString());}
			  ;

jump_statement: (GOTO_TYPE ID ';'
			  | CONTINUE_TYPE ';' {
				  	has_continue = true;
					llvmIrGenerator.insert("\t br label \%" + while_init_label + "\n");
			  }
			  | BREAK_TYPE ';' {
				  	has_break = true;
					llvmIrGenerator.insert("\t br label \%" + while_false_label + "\n");
			  }
			  | RETURN_TYPE ';'
			  | RETURN_TYPE e=expression ';' {
	                int type = $e.varInfo.getType();
                    if(type == CONST_INTEGER){
                        int val = (int) $e.varInfo.getVal();
						llvmIrGenerator.setRetVal(val);
                    } else if(type == DOUBLE){

                    }
			  })
			  {if (TRACEON) System.out.println("\njump statement:\n" + $jump_statement.text.toString());}
			  ;

/*----------------------*/
/*   reserved keywords  */
/*----------------------*/
STRUCT_TYPE: 'struct';
UNION_TYPE: 'union';
ENUM_TYPE: 'enum';
NULL_TYPE: 'null';
INT_TYPE: 'int';
CHAR_TYPE: 'char';
FLOAT_TYPE: 'float';
DOUBLE_TYPE: 'double';
VOID_TYPE: 'void';
WHILE_TYPE: 'while';
IF_TYPE: 'if';
ELSE_TYPE: 'else';
FOR_TYPE: 'for';
SWITCH_TYPE: 'switch';
CASE_TYPE: 'case';
DEFAULT_TYPE: 'default';
CONTINUE_TYPE: 'continue';
RETURN_TYPE: 'return';
BREAK_TYPE: 'break';
GOTO_TYPE: 'goto';
DEFINE_TYPE: '#define';
INCLUDE_TYPE: '#include';
INCLUDE_SYSLIB_TYPE: '<'(LETTER)*'\.'(LETTER)*'>';
CONST_TYPE: 'const';
VOLATILE_TYPE: 'volatile';
STATIC_TYPE: 'static';
EXTERN_TYPE: 'extern';
INLINE_TYPE: 'inline';
SIGNED_TYPE: 'signed';
UNSIGNED_TYPE: 'unsigned';
TYPEDEF_TYPE: 'typedef';
DO_TYPE: 'do';
SIZEOF_TYPE: 'sizeof';

/*----------------------*/
/*       function       */
/*----------------------*/

MAIN_FUNC : 'main';
SCANF_FUNC : 'scanf';
STRLEN_FUNC : 'strlen';
PRINTF_FUNC : 'printf';
MALLOC_FUNC : 'malloc';
FREE_FUNC : 'free';
STRCPY_FUNC
	: 'strcpy';
OPEN_FUNC : 'open';
READ_FUNC : 'read';
WRITE_FUNC : 'write';
CLOSE_FUNC : 'close';
EXIT_FUNC : 'exit';

/*----------------------*/
/*  Compound Operators  */
/*----------------------*/

PP_OP: '++';
MM_OP: '--';
NOT_OP: '!';
ADD_OP: '+';
SUB_OP: '-';
MUL_OP: '*';
MOD_OP: '%';
DIV_OP: '/';
RSHIFT_OP: '<<';
LSHIFT_OP: '>>';
BIT_OR_OP: '|';
BIT_AND_OP: '&';
BIT_XOR_OP: '^';
BIT_NOT_OP: '~';

COMPARE_OP: '==' |
                '<' |
                '<=' |
                '>' |
                '>=' |
                '!=';

CONDITIONAL_OP: '||' |
                '&&';

ID: (LETTER)(LETTER | DIGIT)*;
DEC_NUM: ('0' | ('1'..'9')(DIGIT)*);
FLOAT_NUM: FLOAT_NUM1 | FLOAT_NUM2 | FLOAT_NUM3;
CHAR: '\''.'\'';
LITERAL	:	'"'(.)*'"';
COMMENT_SHORT: '//'(.)*'\n' {$channel=HIDDEN;};
COMMENT_LONG: '/*' (options{greedy=false;}: .)* '*/' {$channel=HIDDEN;};
NEW_LINE: '\r'? '\n' {$channel=HIDDEN;};

fragment FLOAT_NUM1: (DIGIT)+'.'(DIGIT)*;
fragment FLOAT_NUM2: '.'(DIGIT)+;
fragment FLOAT_NUM3: (DIGIT)+;
fragment LETTER: 'a'..'z' | 'A'..'Z' | '_';
fragment DIGIT: '0'..'9';
fragment TYPE: 'char' | 'int' | 'float';
//fragment LITERAL: '"'(.)*'"';

PERIOD: '\.';
BACKSLASH: '\\';
COMMA: ',';
COLON: ':';
// SEMICOLON: ';' {$channel=HIDDEN;};
LEFT_BRACKET: '(';
RIGHT_BRACKET: ')';
LEFT_SQ_BRACKET: '[';
RIGHT_SQ_BRACKET: ']';
LEFT_CUR_BRACKET: '{';
RIGHT_CUR_BRACKET: '}';
DOT_DOT_DOT: '...';
QUESTION_MARK: '?';
WS: (' '|'\r'|'\t')+  {$channel=HIDDEN;}
    ;

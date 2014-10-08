module Super

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO; 						    //print
import Types;					    //Inheritance context
import TypeHelper;					//type/typesymbol to declaration loc
import List;						//zip
import FileInfo;      				//file loc
import String;
import Node;

public void saveSuper(loc projectLoc, InheritanceContext context) {

	result = for (super(loc from, loc to, loc fromDecl) <- context@super) 
			 append "<from>;<to>;<fromDecl>";	
	result = ["from;to;fromDecl"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-super.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}
module Generic


import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO; 						    //print
import Types;					    //Inheritance context
import TypeHelper;					//type/typesymbol to declaration loc
import List;						//zip
import FileInfo;      				//file loc
import String;
import Set;
import Relation;


public void saveGeneric(loc projectLoc, InheritanceContext context) {
	result = for (generic(loc from, loc to, loc fromDecl) <- context@generic, from in context@typesWithObjectSubtype || to in context@typesWithObjectSubtype) 
			 append "<from>;<to>;<fromDecl>";	
	result = ["from;to;fromDecl"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-generic.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

list[Generic] checkCastForGeneric(InheritanceContext ctx, Type targetType, Expression cast) {
	loc targetTypeLoc = getDeclarationLoc(targetType);
	list[Generic] result = [];
	if (cast@typ == object()) {
		result = [generic(t,targetTypeLoc, cast@src) | t <- invert(ctx@directInheritance)[targetTypeLoc]];	
	}
	return result;
}
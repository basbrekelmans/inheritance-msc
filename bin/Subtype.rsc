
module Subtype

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO; 						    //print
import Types;					    //Inheritance context
import TypeHelper;					//type/typesymbol to declaration loc
import List;						//zip
import FileInfo;      				//file loc

public void saveSubtype(loc projectLoc, InheritanceContext ctx) {
	result = for (subtype(bool direct, SubtypeSource source, loc from, loc to, loc fromDecl) <- ctx@subtypes) 
			 append "<direct>;<source>;<from>;<to>;<fromDecl>";	
	result = ["direct?;source;from;to;from declaration"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-subtype.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

public Subtype checkVariableInitializerForSubtype(InheritanceContext ctx, Expression variable, Expression \initializer) {
	loc leftDeclaringType = getDeclarationLoc(variable@typ);
	loc rightDeclaringType = getDeclarationLoc(initializer@typ);
	if (<rightDeclaringType, leftDeclaringType> in ctx@allInheritance) {
		return subtype(<rightDeclaringType, leftDeclaringType> in ctx@directInheritance, varInitialized(), rightDeclaringType, leftDeclaringType, variable@src);
	}
	return noSubtype();
}

public Subtype checkReturnStatementForSubtype(InheritanceContext ctx, loc returnType, Expression expression) {
 	loc expressionType = getDeclarationLoc(expression@typ);
	if (<expressionType, returnType> in ctx@allInheritance) {
		return subtype(<expressionType, returnType> in ctx@directInheritance, returned(), expressionType, returnType, expression@src);
	}
	return noSubtype();
}

public Subtype checkDirectCastForSubtype(InheritanceContext ctx, Expression cast, Type \type, Expression expr) {
	//SUBTYPE: cast a child to a parent type
	loc expressionType = getDeclarationLoc(expr@typ);
	loc targetType = getDeclarationLoc(\type);
	if (<expressionType, targetType> in ctx@allInheritance) {
		return subtype(<expressionType, targetType> in ctx@directInheritance, typeCasted(), expressionType, targetType, cast@src);
	}
	
	return noSubtype();
}

public Subtype checkAssignmentForSubtype(InheritanceContext ctx, Expression assignment, Expression lhs, Expression rhs) {
	loc leftDeclaringType = getDeclarationLoc(lhs@typ);
	loc rightDeclaringType = getDeclarationLoc(rhs@typ);
	if (<rightDeclaringType, leftDeclaringType> in ctx@allInheritance) {
		return subtype(<rightDeclaringType, leftDeclaringType> in ctx@directInheritance, varAssigned(), rightDeclaringType, leftDeclaringType, assignment@src);
	}
	return noSubtype();
}

//check method or constructor call for occurrences of 
//subtyping within its parameters
public Subtype checkCallForSubtype(InheritanceContext ctx, loc methodLoc, list[Expression] arguments) {
	
	if (!(methodLoc in ctx@asts)) return noSubtype();	//no implementation or system call
	Declaration calledMethodAst = ctx@asts[methodLoc];	
	//get formal parameters	  
	list[Declaration] formalParameters = getFormalParameters(calledMethodAst);
	//check each argument against its formal type for subtype usage		
	for (<arg, decl> <- zip(arguments, formalParameters)) {
		loc formalParameterType = getDeclarationLoc(decl@typ);
		loc actualParameterType = getDeclarationLoc(arg@typ);
		if (<actualParameterType, formalParameterType> in ctx@allInheritance) {
			//subtype for parameter
			return subtype(<actualParameterType, formalParameterType> in ctx@directInheritance, parameterPassed(), actualParameterType, formalParameterType, arg@src);
		}
	}    
	return noSubtype();
}

private list[Declaration] getFormalParameters(Declaration ast) {			    	
	switch (ast) {
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
			return parameters;
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):
			return parameters;
		case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
			return parameters;
	}
	throw "Unknown declaration type for formal parameter retrieval: <ast>";
}

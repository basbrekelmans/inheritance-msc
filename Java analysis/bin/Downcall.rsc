module Downcall

import Types;						//InheritanceContext
import TypeHelper;					//getDeclarationLoc
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import FileInfo;      				//file loc
import IO;							//save
import List;						//intercalate
import Set;						    //size
import Relation;					//invert

public void saveDowncall(loc projectLoc, InheritanceContext ctx) {

	result = for (downcall(loc fromType, loc toType, loc fromMethod, loc toMethod, loc calledFrom) <- ctx@downcallCandidates) 
			 append "<fromType>;<toType>;<fromMethod>;<toMethod>;<calledFrom>";	
	result = ["fromType;toType;fromMethod;toMethod;calledFrom"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-downcall.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

public list[Downcall] checkCallForDowncall(InheritanceContext ctx, Expression methodCall, loc methodDeclaringType, loc methodDeclaration) {
	loc calledMethodDeclaration = methodCall@decl;
	list[Downcall] result = [];
	
	if (isMethodGetClass(methodCall) && methodDeclaringType in ctx@declaringTypes) {
		//method is overridden in all derived types automatically
		for (t <- getChildrenNotOverridingOrCallingBase(ctx, methodDeclaringType, methodDeclaration, calledMethodDeclaration, true)) {
			result += downcall(
			t,
			findDirectParent(ctx, t, ctx@declaringTypes[calledMethodDeclaration]),
			calledMethodDeclaration,
			methodDeclaration,
			methodCall@src);
		}
	}
	else if (calledMethodDeclaration in ctx@declaringTypes) {
		//downcall candidate: we are inside method M and we call method X
		//method X needs to be overridden in a derived type				
		for (t <- getChildrenNotOverridingOrCallingBase(ctx, methodDeclaringType, methodDeclaration, calledMethodDeclaration, false)) {
			result += downcall(
			t,
			findDirectParent(ctx, t, ctx@declaringTypes[calledMethodDeclaration]),
			calledMethodDeclaration,
			methodDeclaration,
			methodCall@src);
		}
	}
	return result;
}

private bool isMethodGetClass(Expression methodCall) {
	switch (methodCall) {
		case \methodCall(bool isSuper, str name, list[Expression] arguments): return name == "getClass";
	    case \methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments): return name == "getClass";
	}    
}

private set[loc] getChildrenNotOverridingOrCallingBase(InheritanceContext ctx, loc baseType, loc callSiteMethod, loc methodCalled, bool ignoreExclusions) {
	//get all children that don't override the call site method declaration or 
	//if they override the call site method declaration, call the base method	
	invertedInheritance = invert(ctx@allInheritance);
	set[loc] excluded;
	if (ignoreExclusions) {
		excluded = {};
	} else {
		excluded = { ctx@declaringTypes[m] | m <- ctx@invertedOverrides[callSiteMethod], !(<m, callSiteMethod> in  ctx@m3@methodInvocation) };
		//get all subtrees for exclusion
		excluded += union( { { t | t <- invertedInheritance[e] } | e <- excluded });
	} 
	overriding = { ctx@declaringTypes[m] | m <- ctx@invertedOverrides[methodCalled] };
	overriding += union( { { t | t <- invertedInheritance[i]} | i <- overriding }); 
	return overriding - excluded;
}

public list[Downcall] checkCallForDowncall(InheritanceContext ctx, Expression methodCall, loc methodDeclaringType, loc methodDeclaration, Expression receiver) {
	switch (receiver) {
		case \this() : return checkCallForDowncall(ctx, methodCall, methodDeclaringType, methodDeclaration);
		case \this(Expression qualifier) : return checkCallForDowncall(ctx, methodCall, getDeclarationLoc(qualifier@typ), methodDeclaration);
	}
	return [];
}
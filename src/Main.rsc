module Main

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO;							//print
import Relation; 					//invert
import List; 						//size
import Map;							//size

import Types;						//inheritance context
import TypeHelper;					//method return type
import ModelCache;					//loading models
import InheritanceType;				//inheritance types (CC/CI/II)
import Subtype;
import ExternalReuse;
import InternalReuse;


public void analyzeProject(loc projectLoc) {
	analyzeProject(projectLoc, false);
}

public void analyzeProject(loc projectLoc, bool forceCacheRefresh) {
	M3 model = getM3(projectLoc, forceCacheRefresh);
	map[loc, Declaration] asts = getAsts(projectLoc, forceCacheRefresh);
	print("Creating additional models....");
	rel[loc, loc] directInheritance = model@extends + model@implements;	
	rel[loc, loc] allInheritance = directInheritance++;
	map[loc, loc] declaringTypes = (f:t | <f,t> <- invert(model@containment), t.scheme == "java+class" || t.scheme == "java+interface" || t.scheme == "java+anonymousClass");
	map[loc, TypeSymbol] typeMap = (f:t | <f,t> <- model@types);
	InheritanceContext ctx = ctx();
	ctx@m3 = model;
	ctx@asts = asts;
	ctx@directInheritance = directInheritance;
    ctx@allInheritance = allInheritance;
    ctx@declaringTypes = declaringTypes;
    ctx@typeMap = typeMap;
	println("done");
	getInheritanceTypes(projectLoc, ctx);
	ctx = visitCore(ctx);	
	print("Saving output....");
	saveInternalReuse(projectLoc, ctx);
	saveExternalReuse(projectLoc, ctx);
	saveSubtype(projectLoc, ctx);
	println("done");
}

private InheritanceContext visitCore(InheritanceContext ctx) {
	//visit all methods, field initializers, constructors and type initializers
	list[Reuse] internalReuse = [];
	list[Reuse] externalReuse = [];
	list[Subtype] subtypes = [];
	print("Analyzing project..");
	total = size(ctx@asts);
	n = 0;
	for(k <- ctx@asts) {
		if (n % 300 == 0) {
			print("<n * 100 / total>%..");
		}
		n = n + 1;		
		Declaration ast = ctx@asts[k];
		loc returnType = tryGetReturnType(ast);		
		loc methodDeclaringType = |unresolved:///|;
		if (hasDeclAnnotation(ast)) {
			methodDeclaringType = ctx@declaringTypes[ast@decl];
		}
		visit (ast) {
			//case \arrayAccess(Expression array, Expression index):
			//internal reuse through array access is handled by the \simplename case;
			//external reuse through the qualifiedName case;
			
		    //case \newArray(Type \type, list[Expression] dimensions, Expression init):
		    //handled by other cases
		    
		    //case \newArray(Type \type, list[Expression] dimensions):
		    //handled by other cases
		    
		    //case \arrayInitializer(list[Expression] elements):
		    //handled by other cases
		    
		    case Expression assignment: \assignment(Expression lhs, str operator, Expression rhs):  {
		    	stResult = checkAssignmentForSubtype(ctx, assignment, lhs, rhs);
		    	
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}
		    }			    
		    
		    case Expression castExpression: \cast(Type \type, Expression expression): {
		    	//TODO: Generic attribute
		    	//SUBTYPE: cast a child to a parent type	
		    	stResult = checkDirectCastForSubtype(ctx, castExpression, \type, expression);	    	
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}
		 	}   
		    
		    //case \characterLiteral(str charValue):
		    //not applicable 
		    
		    case Expression ctor: \newObject(Expression expr, Type \type, list[Expression] args, Declaration class): {
		    	stResult = checkCallForSubtype(ctx, ctor@decl, args);
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}
		    }		    
		    case Expression ctor: \newObject(Expression expr, Type \type, list[Expression] args): {
		    	stResult = checkCallForSubtype(ctx, ctor@decl, args);	    
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}
		    }				    
		    case Expression ctor: \newObject(Type \type, list[Expression] args, Declaration class): {	
		    	stResult = checkCallForSubtype(ctx, ctor@decl, args);
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}
		    }
		    case Expression ctor: \newObject(Type \type, list[Expression] args): {			
		    	stResult = checkCallForSubtype(ctx, ctor@decl, args);
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}
		    }		    
		    case \qualifiedName(Expression qualifier, Expression expression): {	
		    	//Requires: accessed item's type, declaring type on accessed item
		    	//Declaring type on parent
		    	result = checkQualifiedNameForExternalReuse(ctx, qualifier, expression);
		    	if (noReuse() !:= result) {
		    		externalReuse += result;
		    	}
		    }
		    //case \conditional(Expression expression, Expression thenBranch, Expression elseBranch):
		    case Expression fieldAccess: \fieldAccess(bool isSuper, Expression expr, str name):		{
		    	//REMARK: isSuper only true when the Super keyword was used; so not relevant	
		    	//INTERNAL REUSE: handles cases this.x and super.x
		    	//EXTERNAL REUSE: handles cases x.y;
		    	result = checkFieldAccessForExternalReuse(ctx, fieldAccess, expr);
		    	if (noReuse() !:= result) {
		    		externalReuse += result;
		    	}
				result = checkFieldAccessForInternalReuse(ctx, methodDeclaringType, fieldAccess);	
		    	if (noReuse() !:= result) {
		    		internalReuse += result;
		    	}
	    	}
		    case Expression fieldAccess: \fieldAccess(bool isSuper, str name): {
		    	//REMARK: isSuper only true when the Super keyword was used; so not relevant for us
		    	//INTERNAL REUSE: handles cases this.x and super.x
		    	//EXTERNAL REUSE: not applicable
				result = checkFieldAccessForInternalReuse(ctx, methodDeclaringType, fieldAccess);	
		    	if (noReuse() !:= result) {
		    		internalReuse += result;
		    	}
		    }
		    //case \instanceof(Expression leftSide, Type rightSide):
		    case Expression methodCall: \methodCall(bool isSuper, str name, list[Expression] arguments): {
		    	//internal reuse
		    	//receiver is not present here; external reuse is not possible. E.g. super.X() or X();
		    	result = checkCallForInternalReuse(ctx, methodCall, methodDeclaringType);
		    	if (noReuse() !:= result) {
		    		internalReuse += result;
		    	}
		    	stResult = checkCallForSubtype(ctx,methodCall@decl, arguments);	
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}	    		
		    }
		    case Expression methodCall: \methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments): {
		    	result = checkCallForInternalReuse(ctx, methodCall, methodDeclaringType);	
		    	if (noReuse() !:= result) {
		    		internalReuse += result;
		    	}	   
		    	result = checkCallForExternalReuse(ctx, methodDeclaringType, methodCall, receiver);	
		    	if (noReuse() !:= result) {
		    		externalReuse += result;
		    	}	     
		    	stResult = checkCallForSubtype(ctx, methodCall@decl, arguments);	
		    	if (noSubtype() !:= stResult) {
		    		subtypes += stResult;
		    	}	    			    							    
		    }
		    //case \null():
		    //case \number(str numberValue):
		    //case \booleanLiteral(bool boolValue):
		    //case \stringLiteral(str stringValue):
		    //case \type(Type \type):
		    //case \variable(str name, int extraDimensions):
		    case Expression variable: \variable(str name, int extraDimensions, Expression \initializer): {				    	
		    	result = checkVariableInitializerForSubtype(ctx, variable, \initializer);
		    	if (noSubtype() !:= result) {
		    		subtypes += result;
		    	}	    		
		    }
		    //case \bracket(Expression expression):
		    //case \this():
		    //case \this(Expression thisExpression):
		    //case \super():
		    //case \declarationExpression(Declaration decl):
		    //case \infix(Expression lhs, str operator, Expression rhs, list[Expression] extendedOperands):
		    //case \postfix(Expression operand, str operator):
		    //case \prefix(str operator, Expression operand):
		    case Expression simpleName: \simpleName(str name): {
		    	//parent is a var access expr:
		    	//handles direct field access through a field name without this or super qualifier
		    	result = checkSimpleNameForInternalReuse(ctx, methodDeclaringType, simpleName);
		    	if (noReuse() !:= result) {
		    		internalReuse += result;
		    	}	    		
		    }
		    //case \markerAnnotation(str typeName):
		    //case \normalAnnotation(str typeName, list[Expression] memberValuePairs):
		    //case \memberValuePair(str name, Expression \value):             
		    //case \singleMemberAnnotation(str typeName, Expression \value):
			// STATEMENTS
	 		case \return(Expression expression): {
	 			//subtype might occur here
		   		result = checkReturnStatementForSubtype(ctx, returnType, expression);
		    	if (noSubtype() !:= result) {
		    		subtypes += result;
		    	}	    		
			}			
		}
	}
	ctx@internalReuse = internalReuse;
	ctx@externalReuse = externalReuse;
	ctx@subtypes = subtypes;
	println("100%..done");
	return ctx;
}

private bool hasDeclAnnotation(Declaration decl) {
	switch (decl) {
		case \field(Type \type, list[Expression] fragments): return false;
	}
	return true;
}

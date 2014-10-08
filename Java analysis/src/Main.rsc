module Main

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import util::Resources;				//projects()
import IO;							//print
import Relation; 					//invert
import List; 						//size
import Map;							//size
import Set; 						//takeOneFrom
import String;						//split
import ValueIO;						//readBinaryValueFile

import FileInfo;					//getBasePath;
import Types;						//inheritance context
import TypeHelper;					//method return type
import ModelCache;					//loading models
import InheritanceType;				//inheritance types (CC/CI/II)
import Subtype;
import ExternalReuse;
import InternalReuse;
import Downcall;
import Super;
import Generic;



public void analyzePreloaded() {
    loc baseLoc = defaultStoragePath();
    set[loc] done = {};
	if (exists(baseLoc + "done.locset"))
		done = readBinaryValueFile(#set[loc], baseLoc + "done.locset");
	println("Loading <size(done)> projects");
	int i = 0;
	for (p <- done) {
		try {
			i = i + 1;
			print("<i>/<size(done)>: <p.authority>...");
			analyzeProject(p, false);
		}
		catch error: {
			println("Error!!!");
			println(error);
			}
	}
	println("Completed");
}

public void analyzeProject(loc projectLoc) {
	analyzeProject(projectLoc, false);
}

public void analyzeProject(loc projectLoc, bool forceCacheRefresh) {
	M3 model = getM3(projectLoc, forceCacheRefresh);
	asts = getAsts(projectLoc, forceCacheRefresh);
	
	//if (forceCacheRefresh) {
	//print("Counting LOC....");
	//writeLinesOfCode(projectLoc);
	//println("done");
	//}
	print("Creating additional models....");
	rel[loc, loc] directInheritance = model@extends + model@implements;	
	rel[loc, loc] allInheritance = directInheritance+;
	map[loc, loc] declaringTypes = (f:t | <t,f> <- model@containment, t.scheme == "java+enum" ||  t.scheme == "java+class" || t.scheme == "java+interface" || t.scheme == "java+anonymousClass");
	map[loc, TypeSymbol] typeMap = (f:t | <f,t> <- model@types);
	InheritanceContext ctx = ctx();
	ctx@m3 = model;
	ctx@asts = asts;
	ctx@directInheritance = directInheritance;
    ctx@allInheritance = allInheritance;
    ctx@super = [];
    ctx@generic = [];
    ctx@typesWithObjectSubtype = {};
    ctx@declaringTypes = declaringTypes;
    ctx@invertedOverrides = invert(model@methodOverrides);
    ctx@typeMap = typeMap;
	println("done");
	getInheritanceTypes(projectLoc, ctx);
	ctx = visitCore(ctx);	
	print("Saving output....");
	saveTypes(projectLoc, ctx);
	saveInternalReuse(projectLoc, ctx);
	saveExternalReuse(projectLoc, ctx);
	saveSubtype(projectLoc, ctx);
	saveDowncall(projectLoc, ctx);
	saveSuper(projectLoc, ctx);
	saveGeneric(projectLoc, ctx);
	println("done");
}

private InheritanceContext visitCore(InheritanceContext ctx) {
	//visit all methods, field initializers, constructors and type initializers
	list[Reuse] internalReuse = [];
	list[Reuse] externalReuse = [];
	list[Subtype] subtypes = [];
	list[Generic] generics = [];
	list[Super] supers = [];
	set[loc] typesWithObjectSubtype = {};
	list[Downcall] downcallCandidates = [];
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
		if (hasDeclAnnotation(ast) && (ast@decl in ctx@declaringTypes)) {
			methodDeclaringType = ctx@declaringTypes[ast@decl];
		}
		else 
		{
			//find field initializer, first occurrence of field 
			//use its declaration to find the containing type
			
			top-down-break visit (ast) {
				  case Expression variable: \variable(str name, int extraDimensions): {
						methodDeclaringType = ctx@declaringTypes[variable@decl];				  		
				  }
    			  case Expression variable: \variable(str name, int extraDimensions, Expression \initializer): {
						methodDeclaringType = ctx@declaringTypes[variable@decl];    			  
    			  }
			}
		
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
		    case Statement foreach: \foreach(Declaration parameter, Expression collection, Statement body): {
		    	<stResult, objectSubtypes> = checkForeachForSubtype(ctx, parameter, collection);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;
		    }
		    case Expression assignment: \assignment(Expression lhs, str operator, Expression rhs):  {
		    	<stResult, objectSubtypes> = checkAssignmentForSubtype(ctx, assignment, lhs, rhs);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
		    }			    
		    
		    case Expression castExpression: \cast(Type \type, Expression expression): {
		    	//TODO: Generic attribute
		    	generics += checkCastForGeneric(ctx, \type, expression);
		    	//SUBTYPE: cast a child to a parent type	
		    	<stResult, objectSubtypes> = checkDirectCastForSubtype(ctx, castExpression, \type, expression);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
		 	}   
		    
		    //case \characterLiteral(str charValue):
		    //not applicable 
		    
		    case Expression ctor: \newObject(Expression expr, Type \type, list[Expression] args, Declaration class): {
		    	<stResult, objectSubtypes> = checkCallForSubtype(ctx, ctor@decl, args);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;
		    }		    
		    case Expression ctor: \newObject(Expression expr, Type \type, list[Expression] args): {
		    	    	<stResult, objectSubtypes> = checkCallForSubtype(ctx, ctor@decl, args);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;
		    }				    
		    case Expression ctor: \newObject(Type \type, list[Expression] args, Declaration class): {	
		        	<stResult, objectSubtypes> = checkCallForSubtype(ctx, ctor@decl, args);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;
		    }
		    case Expression ctor: \newObject(Type \type, list[Expression] args): {			
		        	<stResult, objectSubtypes> = checkCallForSubtype(ctx, ctor@decl, args);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;
		    }		    
		    case \qualifiedName(Expression qualifier, Expression expression): {	
		    	//Requires: accessed item's type, declaring type on accessed item
		    	//Declaring type on parent
		    	externalReuse += checkQualifiedNameForExternalReuse(ctx, qualifier, expression);
		    	
		    }
		    case Expression conditional: \conditional(Expression expression, Expression thenBranch, Expression elseBranch): {
		    	<stResult, objectSubtypes> = checkConditionalForSubtype(ctx, methodDeclaringType, conditional, thenBranch, elseBranch);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
		    }
		    case Expression fieldAccess: \fieldAccess(bool isSuper, Expression expr, str name):		{
		    	//REMARK: isSuper only true when the Super keyword was used; so not relevant	
		    	//INTERNAL REUSE: handles cases this.x and super.x
		    	//EXTERNAL REUSE: handles cases x.y;
		    	externalReuse += checkFieldAccessForExternalReuse(ctx, fieldAccess, expr);
		    	
				internalReuse += checkFieldAccessForInternalReuse(ctx, methodDeclaringType, fieldAccess, expr);	
	    	}
		    case Expression fieldAccess: \fieldAccess(bool isSuper, str name): {
		    	//REMARK: isSuper only true when the Super keyword was used; so not relevant for us
		    	//INTERNAL REUSE: handles cases this.x and super.x
		    	//EXTERNAL REUSE: not applicable
				internalReuse += checkFieldAccessForInternalReuse(ctx, methodDeclaringType, fieldAccess);	
		    }
		    //case \instanceof(Expression leftSide, Type rightSide):
		    case Expression methodCall: \methodCall(bool isSuper, str name, list[Expression] arguments): {
		    	//internal reuse
		    	//receiver is not present here; external reuse is not possible. E.g. super.X() or X();
		    	internalReuse += checkCallForInternalReuse(ctx, methodCall, methodDeclaringType);
	    	
		    	
		    	<stResult, objectSubtypes> = checkCallForSubtype(ctx, methodCall@decl, arguments);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
		    	//downcall candidate possible
		    	if (!isSuper) {
		    	loc decl = hasDeclAnnotation(ast) ? ast@decl : |type://unresolved/|;
		    		downcallCandidates += checkCallForDowncall(ctx, methodCall, methodDeclaringType, decl);
		    	}
		    	
		    }
		    case Expression methodCall: \methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments): {
		    	internalReuse += checkCallForInternalReuse(ctx, methodCall, methodDeclaringType, receiver);	
		    	externalReuse += checkCallForExternalReuse(ctx, methodDeclaringType, receiver, methodCall);	
		    	<stResult, objectSubtypes> = checkCallForSubtype(ctx, methodCall@decl, arguments, receiver);
		    	typesWithObjectSubtype += objectSubtypes;	
		    	subtypes += stResult;
		    	if (!isSuper) {
		    		//if we are in a field initializer, we cannot provide the current method declaration. However; the field initializer
		    		//cannot be overridden, so we don't care about the method declaration
		    		//therefore we provide an unresolved location
		    		loc astDeclaration = |unresolved:///|;
		    		if (hasDeclAnnotation(ast)) {
		    			astDeclaration = ast@decl;
		    		} 
		    		downcallCandidates += checkCallForDowncall(ctx, methodCall, methodDeclaringType, astDeclaration, receiver);
		    	}				    
		    }
		    //case \null():
		    //case \number(str numberValue):
		    //case \booleanLiteral(bool boolValue):
		    //case \stringLiteral(str stringValue):
		    //case \type(Type \type):
		    //case \variable(str name, int extraDimensions):
		    case Expression variable: \variable(str name, int extraDimensions, Expression \initializer): {			
		    	<stResult, objectSubtypes> = checkVariableInitializerForSubtype(ctx, variable, \initializer);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
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
		    	internalReuse += checkSimpleNameForInternalReuse(ctx, methodDeclaringType, simpleName);
		    }
		    //case \markerAnnotation(str typeName):
		    //case \normalAnnotation(str typeName, list[Expression] memberValuePairs):
		    //case \memberValuePair(str name, Expression \value):             
		    //case \singleMemberAnnotation(str typeName, Expression \value):
			// STATEMENTS
	 		case \return(Expression expression): {
	 			//subtype might occur here
		    	<stResult, objectSubtypes> = checkReturnStatementForSubtype(ctx, returnType, expression);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
			}		
			
			case Statement ctorCall: \constructorCall(bool isSuper, Expression expr, list[Expression] arguments): {
				if (isSuper) {
					s = {t | t <- ctx@directInheritance[methodDeclaringType],t.scheme == "java+class" };
					if (size(s) > 0) //nonsystem type
					 supers += super(methodDeclaringType, getOneFrom(s), ctorCall@src);
				}
				
		    	<stResult, objectSubtypes> = checkCallForSubtype(ctx, ctorCall@decl, arguments);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
			}
    		case Statement ctorCall: \constructorCall(bool isSuper, list[Expression] arguments):{
				if (isSuper) {
					s = {t | t <- ctx@directInheritance[methodDeclaringType],t.scheme == "java+class" };
					if (size(s) > 0) //nonsystem type				
					 supers += super(methodDeclaringType, getOneFrom(s), ctorCall@src);
				}
				
		    	<stResult, objectSubtypes> = checkCallForSubtype(ctx, ctorCall@decl, arguments);
		    	subtypes += stResult;
		    	typesWithObjectSubtype += objectSubtypes;	
			}
		}
	}
	ctx@internalReuse = internalReuse;
	ctx@externalReuse = externalReuse;
	ctx@downcallCandidates = downcallCandidates;
	ctx@subtypes = subtypes;
	ctx@super = supers;
	ctx@generic = generics;
	ctx@typesWithObjectSubtype = typesWithObjectSubtype;
	println("100%..done");
	return ctx;
}
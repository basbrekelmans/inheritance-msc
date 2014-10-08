
module Subtype

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO; 						    //print
import Types;					    //Inheritance context
import TypeHelper;					//type/typesymbol to declaration loc
import List;						//zip
import FileInfo;      				//file loc
import String;
import Relation;
import Node;
import String;
import experiments::resource::Resource; //uri decode

private bool applySubtypeToEntireSubtree() {
	return true;
}

public void saveSubtype(loc projectLoc, InheritanceContext ctx) {
	result = for (subtype(bool direct, SubtypeSource source, loc from, loc to, loc fromDecl) <- ctx@subtypes) 
			 append "<direct>;<source>;<from>;<to>;<fromDecl>";	
	result = ["direct?;source;from;to;from declaration"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-subtype.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

public tuple[list[Subtype], set[loc]] checkVariableInitializerForSubtype(InheritanceContext ctx, Expression variable, Expression \initializer) {
	if ("typ" in getAnnotations(variable) && "typ" in getAnnotations(initializer)) {
		return generateSubtypeTree(ctx, initializer@typ, variable@typ, varInitialized(), variable@src);
	}
	return <[],{}>;
}

public tuple[list[Subtype], set[loc]] checkReturnStatementForSubtype(InheritanceContext ctx, loc returnType, Expression expression) {
	if ("typ" in getAnnotations(expression)) {
		return generateSubtypeTree(ctx, expression@typ, class(returnType, []), returned(), expression@src);
	}
	return <[],{}>;
}

public tuple[list[Subtype], set[loc]] checkForeachForSubtype(InheritanceContext ctx, Declaration parameter, Expression collection) {
	declaredType = parameter@typ;
	Type usedType;
	switch (collection@typ) {
		case array(t, _): usedType = t;
		case \interface(_, [p]): usedType = p;
		case class(_, [p]): usedType = p;
		case other: {
			println("UNKNOWN COLLECTION TYPE IN FOREACH");
			iprintln(collection);
			return <[], {}>;
		}
	}
	return generateSubtypeTree(ctx, usedType, declaredType, foreachStatement(), collection@src);
} 

public tuple[list[Subtype], set[loc]] checkDirectCastForSubtype(InheritanceContext ctx, Expression cast, Type \type, Expression expr) {
	list[Subtype] result = [];
	set[loc] typesWithObjectSubtype = {};
	//SUBTYPE: cast a child to a parent type
	<res, objst> =  generateSubtypeTree(ctx, expr@typ, class(getDeclarationLoc(\type), []), typeCasted(), cast@src);
	result += res;
	typesWithObjectSubtype += objst;
	<res, objst> =  generateSubtypeTree(ctx, class(getDeclarationLoc(\type), []), expr@typ, typeCasted(), cast@src);
	result += res;
	typesWithObjectSubtype += objst;
 
	//Sideways cast:
	//C implements P1
	//C implements P2
	//void method(P1 p1) {
	//P2 p2 = (P2)p1; // sideways cast
	//One is the “sideways” cast,	
	//where Java allows what looks like a cast between unrelated types. In the example in	
	//Figure 5, the cast will be successful provided an instance of C is passed to the method.	
	//Such situations represent use of the subtype relationship between C and its parents, and}	
	//so must be detected in order to correctly identify all subtype uses.
	loc from = getDeclarationLoc(expr@typ);
	loc to = getDeclarationLoc(\type);
	if (from != to && !(<from,to> in ctx@allInheritance) && !(<to, from> in ctx@allInheritance)) {
		//sideways cast
		inverted = invert(ctx@allInheritance);
		set[loc] targets = inverted[from] & inverted[to];
	 	//targets contains all types that have both from and to as parent
	 	//all targets get a subtype relation to their parents (parents are from and to)
	 	result += [\subtype(true, sidewaysCast(), t, from, cast@src) | t <-targets];
	 	result += [\subtype(true, sidewaysCast(), t, to, cast@src) | t <-targets];
	}
		return <result, typesWithObjectSubtype>;
}

public tuple[list[Subtype], set[loc]] checkAssignmentForSubtype(InheritanceContext ctx, Expression assignment, Expression lhs, Expression rhs) {
	if ("typ" in getAnnotations(lhs) && "typ" in getAnnotations(rhs)) {
		return generateSubtypeTree(ctx, rhs@typ, lhs@typ, varAssigned(), assignment@src);
	}
	return <[],{}>;
}

//check method or constructor call for occurrences of 
//subtyping within its parameters
public tuple[list[Subtype], set[loc]] checkCallForSubtype(InheritanceContext ctx, loc methodLoc, list[Expression] arguments) {
	list[Subtype] result = checkArgumentsForThisChangingType(ctx, arguments);
	set[loc] typesWithObjectSubtype = {};
	
	if (methodLoc in ctx@asts) {
		Declaration calledMethodAst = ctx@asts[methodLoc];	
		
		//get formal parameters	  
		list[TypeSymbol] formalParameters = getParameters(ctx, methodLoc, arguments, \void());
		if (size(formalParameters) > 0) {
		
			if (size(formalParameters) != size(arguments)) {
				println("could not detect params at <arguments[0]@src>");
				return <[],{}>;
			}
			//check each argument against its formal type for subtype usage		
			for (<arg, decl> <- zip(arguments, formalParameters)) {
				<res,objst> = generateSubtypeTree(ctx, arg@typ, decl, parameterPassed(), arg@src);
				typesWithObjectSubtype += objst;
				result += res;
			}  
		}
	}
	
	return <result, typesWithObjectSubtype>;
}

private list[Subtype] checkArgumentsForThisChangingType(InheritanceContext ctx, list[Expression] arguments) {
	list[Subtype] result = [];
	typesWithObjectSubtype = {};
	for (arg <- arguments) {
		loc actualParameterType = getDeclarationLoc(arg@typ);
		if (this() := arg) {
			result += [subtype(false, thisChangingType(), child,actualParameterType, arg@src) | child <- invert(ctx@allInheritance)[actualParameterType]];
		} else if (this(Expression qualifier) := arg) {
			loc thisType = getDeclarationLoc(qualifier@typ);
			result += [subtype(false, thisChangingType(), child,actualParameterType, arg@src) | child <- invert(ctx@allInheritance)[thisType]];
		}
	}
	return result;
}

//check method or constructor call for occurrences of 
//subtyping within its parameters
public tuple[list[Subtype], set[loc]] checkCallForSubtype(InheritanceContext ctx, loc methodLoc, list[Expression] arguments, Expression receiver) {
	
	result = checkArgumentsForThisChangingType(ctx, arguments);
	typesWithObjectSubtype = {};
	list[TypeSymbol] formalParameters = getParameters(ctx, methodLoc, arguments, receiver@typ);
		
	if (size(arguments) != size(formalParameters)) {
			println("could not detect params at <receiver@src>");
			println(methodLoc);
			iprintln(formalParameters);
			println("Supplied arguments were:");
			iprintln(arguments);
			throw "parameter error";
		return [];
	}
	//check each argument against its formal type for subtype usage		
	for (<arg, decl> <- zip(arguments, formalParameters)) {		
		<res,objst> = generateSubtypeTree(ctx, arg@typ, decl, parameterPassed(), arg@src);
		typesWithObjectSubtype += objst;
		result += res;
	}    	
	return <result, typesWithObjectSubtype>;
}

private list[TypeSymbol] getParameters(InheritanceContext ctx, loc methodLoc, list[Expression] arguments, TypeSymbol receiverType) {
	list[TypeSymbol] formalParameters = [];
	bool possibleVarArgs = false;
	if (methodLoc in ctx@asts) {
		formalParameters = [p@typ | p <- getFormalParameters(ctx@asts[methodLoc])];
		possibleVarArgs = size(formalParameters) > 0 && array(_,_) := formalParameters[size(formalParameters) -1];
	} else {
		if (/.*\(<paramList:.*>\)/ := methodLoc.uri) {
			for (s <- split(",", paramList)) {
				str scheme = replaceAll(s, ".", "/");
				if (scheme == "java/lang/Object") {
					formalParameters += object();
					continue;
				} else if (scheme == "") {
					continue;
				}
				loc classLoc = toLocation("java+class:///<scheme>");
				loc interfaceLoc = toLocation("java+interface:///<scheme>");
				if (classLoc in ctx@m3@containment) {
					formalParameters += class(classLoc, []);
				} else if (interfaceLoc in ctx@m3@containment) {
					formalParameters += interface(interfaceLoc, []);
				} else if (s in primitiveTypes()) {
					formalParameters += \void();				
				} else if (/^\w+$/ := s) {
					//unseparated single word, must be a type variable					
					list[TypeSymbol] typeParams = [];
					if (\interface(loc decl, list[TypeSymbol] parameters) := receiverType) {
						typeParams = parameters;
					} else if (\class(loc decl, list[TypeSymbol] parameters) := receiverType) {
						typeParams = parameters;
						
					} 
					
					if (size(typeParams) == 0) {
						//no type params specified, but argument requires a type parameter
						formalParameters += object();
					}
					else if (size(typeParams) == 1) {
						//a single type parameter was specified
						formalParameters += typeParams[0]; 
					}
					else {
						//unknown situation, multiple type parameters cannot be mapped
						formalParameters += \void();
					}
				} else {
					//some external type, e.g. java.lang.String
					formalParameters += \class(classLoc, []);
				}
			}
			
			
			possibleVarArgs = endsWith(uriDecode(paramList), "[]");			
		}
	}	
			
	if (possibleVarArgs) {	
		if (size(formalParameters) < size(arguments)) {
			lastParam = formalParameters[size(formalParameters) - 1];				
			formalParameters += [lastParam | i <- [size(formalParameters)..size(arguments)]];						
		} else if (size(formalParameters) > size(arguments)) {
			formalParameters = formalParameters[..size(arguments)];
		}
	}
	return formalParameters;
}

@memo
private set[str] primitiveTypes() {
	return { "byte", "short", "int", "long", "float", "double", "boolean", "char" };
}

public tuple[list[Subtype],set[loc]] checkConditionalForSubtype(InheritanceContext ctx, loc declaration, Expression cond, Expression thenBranch, Expression elseBranch) {
	list[Subtype] subtypes       = [];
	set[loc]      objectSubtypes = {};
	
	<res,objst> = generateSubtypeTree(ctx, thenBranch@typ, cond@typ, conditional(), thenBranch@src);
	objectSubtypes += objst;
	subtypes += res;
	
	<res2,objst2> = generateSubtypeTree(ctx, elseBranch@typ, cond@typ, conditional(), elseBranch@src);
	objectSubtypes += objst2;
	subtypes += res2;
	
	return <subtypes,objectSubtypes>;
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

private tuple[list[Subtype], set[loc]] generateSubtypeTree(InheritanceContext ctx, TypeSymbol child, TypeSymbol parent, SubtypeSource source, loc comingFromDeclaration) {
	list[Subtype] subtypes       = [];
	set[loc]      objectSubtypes = {};
	
	loc childDeclaration = getDeclarationLoc(child);
	loc parentDeclaration = getDeclarationLoc(parent);
	bool applyChildren = false, objectParent = false;
	if (parent == object()) {
		objectParent = true;
		parentDeclaration = findHighestParent(ctx, childDeclaration);
	} 
	if (<childDeclaration, parentDeclaration> in ctx@allInheritance) {
		applyChildren = true;
	}
	set[loc] children = (applyChildren || objectParent) ? /* invert(ctx@allInheritance)[childDeclaration] + */ getPathToParent(ctx, childDeclaration, parentDeclaration) : {}; 
	if (objectParent) {
		//parent declaration is not really correct here, so we need to find the highest-up in the chain
		//to assign indirect subtypes to instead
		objectSubtypes = children;
	}
	if (applyChildren) {
		subtypes = [subtype(c == childDeclaration, source, c, findDirectParent(ctx, c, parentDeclaration), comingFromDeclaration) |
					 c <- children];
	}
	
	return <subtypes,objectSubtypes>;
}
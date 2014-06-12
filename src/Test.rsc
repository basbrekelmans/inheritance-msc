module Test

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO;  						//print
import Set;			 				//in set
import Relation; 					//inheritance relation
import String; 						//printing
import Map;						    //typeMap
import List; 						//zip

public void analyze(loc projectLoc) 
{
	bool shouldPrintSubtype = false;
	bool shouldPrintReuse = true;
	
	println("Creating M3....");
	M3 model = createM3FromEclipseProject(projectLoc);
	println("Creating direct inheritance rel....");
	rel[loc, loc] directInheritance = model@extends + model@implements;
	println("Creating all inheritance rel....");
	rel[loc, loc] allInheritance = directInheritance++;
	println("Creating declaring type location map....");
	map[loc, loc] declaringTypes = (f:t | <f,t> <- invert(model@containment), t.scheme == "java+class" || t.scheme == "java+interface" || t.scheme == "java+anonymousClass");
	println("Creating method ast map....");
	map[loc, Declaration] methodAsts = createAstMap(projectLoc);
	println("Creating type map....");
	map[loc, TypeSymbol] typeMap = (f:t | <f,t> <- model@types);
	calculateInheritanceTypes();
	//calculateInternalReuse();
	calculateReuse();
}


private void calculateInheritanceTypes() {
	println("!!! BEGIN INHERITANCE TYPES !!!");
	println("Type;from;to;direct?");
	
	for (<loc from,loc to> <- directInheritance) {
		 println("<getInheritanceType(from, to)>;<from>;<to>;true");
	}
	for (<loc from,loc to> <- allInheritance - directInheritance) {
		 println("<getInheritanceType(from, to)>;<from>;<to>;false");
	}
}

private void calculateReuse() {
	println("!!! BEGIN REUSE !!!");
	println("Internal/External;Direct?;Type;FromType;ToType;From;To");
	rel[str, loc] declaredTypes;
	for(<methodLoc, src> <- model@declarations, methodLoc.scheme == "java+method" || methodLoc.scheme == "java+constructor") {
		if (!(methodLoc in methodAsts)) continue;	//default constructor encountered
		Declaration methodAst = methodAsts[methodLoc];
		map[loc, loc] variableDeclaringTypes;
		loc methodDeclaringType = declaringTypes[methodLoc];
		loc methodReturnType = |type://unresolved/|;
		switch (methodAst) {
			case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
				methodReturnType = getDeclarationLoc(\return);
    		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):
				methodReturnType = getDeclarationLoc(\return);
		}
		visit (methodAst) {			
			//case \arrayAccess(Expression array, Expression index):
			//internal reuse through array access is handled by the \simplename case;
			//external reuse through the qualifiedName case;
			
		    //case \newArray(Type \type, list[Expression] dimensions, Expression init):
		    //handled by other cases
		    
		    //case \newArray(Type \type, list[Expression] dimensions):
		    //handled by other cases
		    
		    //case \arrayInitializer(list[Expression] elements):
		    //handled by other cases
		    
		    case \assignment(Expression lhs, str operator, Expression rhs):  {
		    	checkAssignmentForSubtype(allInheritance, directInheritance, assignment, lhs, rhs);
		    }				    
		    
		    case castExpression: \cast(Type \type, Expression expression):
		    	//TODO: Generic attribute
		    	//SUBTYPE: cast a child to a parent type
		    	checkDirectCastForSubtype(allInheritance, directInheritance, castExpression, \type, expression);
		    }
		    //case \characterLiteral(str charValue):
		    //not applicable 
		    
		    case \newObject(Expression expr, Type \type, list[Expression] args, Declaration class): {
		    	loc calledMethodDeclaration = parentExpr@decl;
		    	checkSubtypeForMethodCall(calledMethodDeclaration, args, parentExpr@src);
		    }
		    
		    case \newObject(Expression expr, Type \type, list[Expression] args): {
		    	loc calledMethodDeclaration = parentExpr@decl;
		    	checkSubtypeForMethodCall(calledMethodDeclaration, args, parentExpr@src);				    
		    }				    
		    case \newObject(Type \type, list[Expression] args, Declaration class): {				    
		    	loc calledMethodDeclaration = parentExpr@decl;
		    	checkSubtypeForMethodCall(calledMethodDeclaration, args, parentExpr@src);
		    }
		    
		    case \newObject(Type \type, list[Expression] args): {				    
		    	loc calledMethodDeclaration = parentExpr@decl;
		    	checkSubtypeForMethodCall(calledMethodDeclaration, args, parentExpr@src);
		    }
		    
		    case \qualifiedName(Expression qualifier, Expression expression): {	
		    	//Requires: accessed item's type, declaring type on accessed item
		    	//Declaring type on parent
		    	if (qualifier@decl in typeMap) {
			    	loc variableDeclaringType = getDeclarationLoc(typeMap[qualifier@decl]);	
			    	loc variableUsedType = getDeclarationLoc(qualifier@typ);		
			    	if (variableDeclaringType != |type://external| && variableUsedType != |type://external|) {
				    	if (<variableDeclaringType, variableUsedType> in allInheritance) {
				    		printReuse("external", <variableDeclaringType, variableUsedType> in directInheritance, "field access", variableDeclaringType, variableUsedType, qualifier@src, expression@decl);
				    	}
			    	}	
		    	}
		    }
		    //case \conditional(Expression expression, Expression thenBranch, Expression elseBranch):
		    case \fieldAccess(bool isSuper, Expression expr, str name):		{
		    	//REMARK: isSuper only true when the Super keyword was used; so not relevant	
		    	//INTERNAL REUSE: handles cases this.x and super.x
		    	//EXTERNAL REUSE: not applicable
		    	if (parentExpr@decl in declaringTypes) {
		    		loc declaringType = declaringTypes[parentExpr@decl];
					bool isInternalReuse = (<methodDeclaringType, declaringType> in allInheritance);	
			    	if (isInternalReuse) {				    	
			    		printReuse("internal", <methodDeclaringType, declaringType> in directInheritance, "field access", methodDeclaringType, declaringType, parentExpr@src, parentExpr@decl);
			    	}
			    	else {
			    		loc expressionDeclaration = getDeclarationLoc(expr@typ);
			    		loc expressionFieldDeclaration = parentExpr@decl;
			    		if (expressionFieldDeclaration in declaringTypes) {
			    			loc fieldDeclaringType = declaringTypes[expressionFieldDeclaration];
							bool isExternalReuse = (<expressionDeclaration, fieldDeclaringType> in allInheritance);
				    		if (isExternalReuse) {				    	
				    			printReuse("external", <expressionDeclaration, fieldDeclaringType> in directInheritance, "field access", expressionDeclaration, fieldDeclaringType, parentExpr@src, parentExpr@decl);
				    		}				    								    			
			    		}
			    		 
		    		}
			    	
		    	}			
		    	
		    			
		    }	    
				    case \fieldAccess(bool isSuper, str name): {
				    	//REMARK: isSuper only true when the Super keyword was used; so not relevant	
				    	//INTERNAL REUSE: handles cases this.x and super.x
				    	//EXTERNAL REUSE: not applicable
						loc declaringType = declaringTypes[parentExpr@decl];
						bool isInheritance = (<methodDeclaringType, declaringType> in allInheritance);	
				    	if (isInheritance) {	 	
				    		printReuse("internal", <methodDeclaringType, declaringType> in directInheritance, "field access", methodDeclaringType, declaringType, parentExpr@src, parentExpr@decl);
				    	}
				    }
				    //case \instanceof(Expression leftSide, Type rightSide):
				    case \methodCall(bool isSuper, str name, list[Expression] arguments): {
				    	//internal reuse
				    	loc calledMethodDeclaration = parentExpr@decl;
				    	if (calledMethodDeclaration in declaringTypes) {
					    	loc calledType = declaringTypes[calledMethodDeclaration];
							bool isInheritance = (<methodDeclaringType, calledType> in allInheritance);
							if (isInheritance) {						
					    		printReuse("internal", <methodDeclaringType, calledType> in directInheritance, "method call", methodDeclaringType, calledType, parentExpr@src, calledMethodDeclaration);
							} //receiver is not present here; external reuse is not possible. E.g. super.X() or X();
				    	}
				    	checkSubtypeForMethodCall(calledMethodDeclaration, arguments, parentExpr@src);
				    		
				    }
				    case \methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments): {
				    	loc calledMethodDeclaration = parentExpr@decl;
				    	if (calledMethodDeclaration in declaringTypes) {
					    	loc calledType = declaringTypes[calledMethodDeclaration];
							bool isInheritance = (<methodDeclaringType, calledType> in allInheritance);
							if (isInheritance) {						
					    		printReuse("internal", <methodDeclaringType, calledType> in directInheritance, "method call", methodDeclaringType, calledType, parentExpr@src, calledMethodDeclaration);
							}	else if (methodDeclaringType != calledType) {
								//possible external reuse
								loc receiverType = getDeclarationLoc(receiver@typ);
								if (receiverType != |type://external| && <receiverType, calledType> in allInheritance) {
									//type of method call receiver is known; declared somewhere in 
									//our code. External reuse
									printReuse("external", <receiverType, calledType> in directInheritance, "method call", receiverType, calledType, parentExpr@src, calledMethodDeclaration);	
								}
							}	
				    	}						    	
				    	checkSubtypeForMethodCall(calledMethodDeclaration, arguments, parentExpr@src);		    							    
				    }
				    //case \null():
				    //case \number(str numberValue):
				    //case \booleanLiteral(bool boolValue):
				    //case \stringLiteral(str stringValue):
				    //case \type(Type \type):
				    //case \variable(str name, int extraDimensions):
				    case \variable(str name, int extraDimensions, Expression \initializer): {				    	
				    	loc leftDeclaringType = getDeclarationLoc(parentExpr@typ);
				    	loc rightDeclaringType = getDeclarationLoc(initializer@typ);
				    	if (<rightDeclaringType, leftDeclaringType> in allInheritance) {
				    		printSubtype(<rightDeclaringType, leftDeclaringType> in directInheritance, "assignment-initializer", rightDeclaringType, leftDeclaringType, parentExpr@src);
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
				    case \simpleName(str name): {
				    	//parent is a var access expr:
				    	//handles direct field access through a field name without this or super qualifier
				    	loc declaration = parentExpr@decl;
				    	if (declaration.scheme == "java+field" && declaration in declaringTypes) {
				    		loc declaringType = declaringTypes[declaration];
							bool isInheritance = (<methodDeclaringType, declaringType> in allInheritance);
							if (isInheritance) {	
								printReuse("internal", <methodDeclaringType, declaringType> in directInheritance, "field access", methodDeclaringType, declaringType, parentExpr@src, declaration);
							}
				    	}
				    }
				    //case \markerAnnotation(str typeName):
				    //case \normalAnnotation(str typeName, list[Expression] memberValuePairs):
				    //case \memberValuePair(str name, Expression \value):             
				    //case \singleMemberAnnotation(str typeName, Expression \value):
				}
				
			}			   
			case Statement parentStmt: {
				switch (parentStmt) {
					// STATEMENTS
			 		case \return(Expression expression): {
			 		//required for return
				    	loc expressionType = getDeclarationLoc(expression@typ);
				    	if (<expressionType, methodReturnType> in allInheritance) {
				    		printSubtype(<expressionType, methodReturnType> in directInheritance, "return", expressionType, methodReturnType, expression@src);
				    	}
					}
				}
			}			
		}
	}	
}

private void printReuse(str \type, bool direct, str source, loc from, loc to, loc fromDecl, loc toDecl) {
	if (shouldPrintReuse) {
		println("<\type> reuse;<direct>;<source>;<from>;<to>;<fromDecl>;<toDecl>");
	}
}

private void calculateInternalReuse() {
	println("Internal reuse");
	println("Type;from;to");
	//field access
	
	for (<f,t> <- [<f,t> | <f,t> <- model@fieldAccess, 
						   f in declaringTypes, t in declaringTypes, 
						   declaringTypes[f] != declaringTypes[t]],
						   <declaringTypes[f], declaringTypes[t]> in allInheritance) {
		fromType = declaringTypes[f];
		toType = declaringTypes[t];
		println("FieldAccess;<fromType>;<toType>");
	}
	
	for (<f,t> <- [<f,t> | <f,t> <- model@methodInvocation, 
						   f in declaringTypes, t in declaringTypes, 
						   declaringTypes[f] != declaringTypes[t]],
						   <declaringTypes[f], declaringTypes[t]> in allInheritance) {
		fromType = declaringTypes[f];
		toType = declaringTypes[t];
			println("MethodInvocation;<fromType>;<toType>");
	}

}


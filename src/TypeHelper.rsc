module TypeHelper

import lang::java::jdt::m3::Core;	//M3
import lang::java::m3::AST;			//Declaration
import Types;						//InheritanceContext
import Set;							//size
import IO;

public loc getDeclarationLoc(Type t) {
	switch (t) {
		case \simpleType(Expression name):
			return getDeclarationLoc(name@typ);
			
		case \qualifiedType(Type \qualifier, _): 
			return getDeclarationLoc(qualifier);
			
		case \parameterizedType(Type inner):
			return getDeclarationLoc(inner);
	}
	return |type://external|;
}

public loc getDeclarationLoc(TypeSymbol t) {
	switch (t) {
		case \class(loc classLoc, _):
			return classLoc;
		case \interface(loc interfaceLoc, _): 
			return interfaceLoc;
	}
	return |type://external|;
}

public bool isTypeExternal(InheritanceContext ctx, loc declaration) {
	return size((ctx@m3)@declarations[declaration]) == 0;
}

public loc tryGetReturnType(Declaration methodAst) {	
	loc methodReturnType = |type://unresolved/|;
	switch (methodAst) {
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
			methodReturnType = getDeclarationLoc(\return);
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):
			methodReturnType = getDeclarationLoc(\return);
	}
	return methodReturnType;
}
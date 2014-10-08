module TypeHelper

import lang::java::jdt::m3::Core;	//M3
import lang::java::m3::AST;			//Declaration
import Types;						//InheritanceContext
import Set;							//size
import IO;
import FileInfo;
import List;						//zip
import Node;						//getAnnotations
import Relation;

 
public void saveTypes(loc projectLoc, InheritanceContext ctx) {

	rel[loc,loc] inverted = invert(ctx@allInheritance);
	set[loc] exceptions = inverted[|java+class:///java/lang/Throwable|] + inverted[|java+class:///java/lang/Exception|] + inverted[|java+class:///java/lang/Error|];

	result = for (t <- ({ctx@declaringTypes[k] | k <- ctx@declaringTypes} + domain(ctx@allInheritance) + range(ctx@allInheritance))) 
			 append "<t>;<!isTypeExternal(ctx, t)>;<t in exceptions>";	
	result = ["type;system type?;exception?"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-types.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

public set[loc] getPathToParent(InheritanceContext ctx, loc child, loc parent) {
	set[loc] path = {};
	if (<child, parent> in ctx@directInheritance) {
		path = {child};
	}
	else if (<child, parent> in ctx@allInheritance) {
		path = {};
		for (p <- ctx@directInheritance[child]) {
			path = {child} + getPathToParent(ctx, p, parent);
			if (size(path) > 1) 
				break;
		}
	}
	return path;
}

public loc getDeclarationLoc(Type t) {
	switch (t) {
		case \simpleType(Expression name):
			return getDeclarationLoc(name@typ);
			
		case \qualifiedType(Type \qualifier, _): 
			return getDeclarationLoc(qualifier);
			
		case \parameterizedType(Type inner):
			return getDeclarationLoc(inner);
		case \object(): 
			return |java+class://java/lang/Object/|;
	}
	return |type://external|;
}

public loc getDeclarationLoc(TypeSymbol t, map[loc, loc] typeParameters) {
	switch (t) {
		case \class(loc classLoc, _):
			return classLoc;
		case \interface(loc interfaceLoc, _): 
			return interfaceLoc;
		case \object(): return |java+class://java/lang/Object|;
		case \typeParameter(loc decl, _):
			if (decl in typeParameters) {			
				return typeParameters[decl];		
			}
	}
	return |type://external|;
}

public loc getDeclarationLoc(TypeSymbol t) {
	switch (t) {
		case \class(loc classLoc, _):
			return classLoc;
		case \interface(loc interfaceLoc, _): 
			return interfaceLoc;
		case \typeParameter(loc decl, _):
			return decl;
		case \object(): return |java+class://java/lang/Object|;
		case \method(loc decl, list[TypeSymbol] typeParameters, TypeSymbol returnType, list[TypeSymbol] parameters):
			return decl;
	}
	return |type://external|;
}



public map[loc, loc] getBoundTypeParameters(InheritanceContext ctx, TypeSymbol receiverType) {
	
	loc methodDeclaringType = getDeclarationLoc(receiverType);
	
	if (methodDeclaringType in ctx@m3@typeDependency) {
		typeAst = getOneFrom(ctx@m3@typeDependency[methodDeclaringType]);
		formalTypeParameters = getParameters(typeAst@typ);
		actualTypeParameters = getParameters(receiverType);
		
		if (size(formalTypeParameters) != size(actualTypeParameters)) {
			//TODO: bugfix on interface type parameters
			return ();
		}
		return (f: a | <f,a> <- zip(formalTypeParameters, actualTypeParameters));		
	}
	return ();
}

private list[loc] getParameters(TypeSymbol t) {
	switch(t) {
		case \class(_, list[TypeSymbol] parameters): return mapper(parameters, getDeclarationLoc);
		case \interface(_, list[TypeSymbol] parameters): return  mapper(parameters, getDeclarationLoc);
	}
	return [];
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

public bool hasDeclAnnotation(node decl) {
	return "decl" in getAnnotations(decl);
}


public loc findDirectParent(InheritanceContext ctx, loc child, loc parent) {
	if (<child, parent> in ctx@directInheritance) {
		return parent;
	}
	else 
	{
		for (c <- ctx@directInheritance[child]) {
			if (searchPath(ctx, c, parent)) {
				return c;
			}
		}
	}
	throw "Could not find direct parent of relationship <child> to <parent>";
}

public loc findHighestParent(InheritanceContext ctx, loc child) {
	set[loc] parents = { p | p <- ctx@directInheritance[child], p.scheme == child.scheme };
	if (size(parents) != 1) return child;
	return findHighestParent(ctx, getOneFrom(parents));
}

private bool searchPath(InheritanceContext ctx, loc child, loc parent) {
	if (<child, parent> in ctx@directInheritance) {
		return true;
	} else {
		for (c <- ctx@directInheritance[child]) {
			if (searchPath(ctx, c, parent)) {
				return true;
			}
		}
		return false;
	}
}
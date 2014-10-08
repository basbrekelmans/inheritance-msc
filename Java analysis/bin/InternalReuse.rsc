module InternalReuse

import Types;						//InheritanceContext
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import ReuseHelper;
import FileInfo;      				//file loc
import IO;							//saving
import List;						//intercalate
import TypeHelper;					//getDeclarationLoc;
    
    
public void saveInternalReuse(loc projectLoc, InheritanceContext ctx) {

	result = for (reuse(bool direct, ReuseSource source, loc from, loc to, loc fromDecl, loc toDecl) <- ctx@internalReuse) 
			 append "<direct>;<source>;<from>;<to>;<fromDecl>";	
	result = ["direct?;source;from;to;from declaration; to declaration"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-internal-reuse.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}
    
public list[Reuse] checkFieldAccessForInternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression fieldAccess) {	
	if (fieldAccess@decl in ctx@declaringTypes) {		    		
		loc declaringType = ctx@declaringTypes[fieldAccess@decl];
		return getReuse(ctx, \class(methodDeclaringType, []), \class(declaringType, []), fieldAccessed(), fieldAccess@src, fieldAccess@decl);
	}	
	return [];
}

public list[Reuse] checkFieldAccessForInternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression fieldAccess, Expression expr) {	
	switch (expr) {
		case \this() : return checkFieldAccessForInternalReuse(ctx, methodDeclaringType, fieldAccess);
		case \this(Expression qualifier) : return checkFieldAccessForInternalReuse(ctx, getDeclarationLoc(qualifier@typ), fieldAccess);
	}
	return [];
}

public list[Reuse] checkSimpleNameForInternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression simpleName) {
	loc declaration = simpleName@decl;
	if (declaration.scheme == "java+field" && declaration in ctx@declaringTypes) {
		loc declaringType = ctx@declaringTypes[declaration];
		return getReuse(ctx, \class(methodDeclaringType, []), \class(declaringType, []), fieldAccessed(), simpleName@src, declaration);		
	}
	return [];
}

public list[Reuse] checkCallForInternalReuse(InheritanceContext ctx, Expression methodCall, loc methodDeclaringType) {
	loc calledMethodDeclaration = methodCall@decl;
	if (calledMethodDeclaration in ctx@declaringTypes) {
    	loc calledType = ctx@declaringTypes[calledMethodDeclaration];	
		return getReuse(ctx, \class(methodDeclaringType, []), \class(calledType, []), methodCalled(), methodCall@src, calledMethodDeclaration);
	}
	return [];
}

public list[Reuse] checkCallForInternalReuse(InheritanceContext ctx, Expression methodCall, loc methodDeclaringType, Expression receiver) {
	switch (receiver) {
		case \this() : return checkCallForInternalReuse(ctx, methodCall, methodDeclaringType);
		case \this(Expression qualifier) : return checkCallForInternalReuse(ctx, methodCall, getDeclarationLoc(qualifier@typ));
	}
	return [];
}
module ExternalReuse

import Types;						//InheritanceContext
import TypeHelper;					//getDeclarationLoc
import ReuseHelper;

import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import FileInfo;      				//file loc
import IO;							//save
import List;						//intercalate
import Node;						//getannotations

public void saveExternalReuse(loc projectLoc, InheritanceContext ctx) { 
	result = for (reuse(bool direct, ReuseSource source, loc from, loc to, loc fromDecl, loc toDecl) <- ctx@externalReuse) 
			 append "<direct>;<source>;<from>;<to>;<fromDecl>";	
	result = ["direct?;source;from;to;from declaration; to declaration"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-external-reuse.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

public list[Reuse] checkQualifiedNameForExternalReuse(InheritanceContext ctx, Expression qualifier, Expression expression) {
	if (qualifier@decl in ctx@typeMap && "typ" in getAnnotations(qualifier)) {
    	loc variableDeclaringType = getDeclarationLoc(qualifier@typ);	
    	if (expression@decl == |unresolved:///|) {
    		//unresolved expression; cannot be system type
    		return [];
    	}
    	loc declaration = expression@decl;
    	if ("java+enumConstant" == declaration.scheme) {    	
    		//or enum constant, cannot be external reuse
    		return [];
    	}
    	if (!(declaration in ctx@declaringTypes)) {
    		println("DECLARATION <declaration> NOT IN DECLARING TYPES");
    		return [];
    	}
    	return getReuse(ctx, qualifier@typ, \class(ctx@declaringTypes[expression@decl], []), fieldAccessed(), qualifier@src, declaration); 
	}
	return [];
}

public list[Reuse] checkFieldAccessForExternalReuse(InheritanceContext ctx, Expression fieldAccess, Expression expr) {
	if (this() !:= expr && this(Expression q) !:= expr && hasDeclAnnotation(fieldAccess) && fieldAccess@decl in ctx@declaringTypes) {
		loc currentDeclaringType = ctx@declaringTypes[fieldAccess@decl];
		loc expressionDeclaration = getDeclarationLoc(expr@typ);
    	return getReuse(ctx, \class(currentDeclaringType, []), \class(expressionDeclaration, []), fieldAccessed(), fieldAccess@src, fieldAccess@decl);
	}		
	return [];
}
public list[Reuse] checkCallForExternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression receiver, Expression methodCall) {
	if (this() !:= receiver && this(Expression q) !:= receiver && methodCall@decl in ctx@declaringTypes) {
    	return getReuse(ctx, \class(methodDeclaringType, []), \class(ctx@declaringTypes[methodCall@decl], []), methodCalled(), methodCall@src, methodCall@decl);
	}					
	return [];
}

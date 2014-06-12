module InternalReuse

import Types;						//InheritanceContext
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import FileInfo;      				//file loc
import IO;							//saving
import List;						//intercalate
    
    
public void saveInternalReuse(loc projectLoc, InheritanceContext ctx) {

	result = for (reuse(bool direct, ReuseSource source, loc from, loc to, loc fromDecl, loc toDecl) <- ctx@internalReuse) 
			 append "<direct>;<source>;<from>;<to>;<fromDecl>";	
	result = ["direct?;source;from;to;from declaration; to declaration"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-internal-reuse.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}
    
public Reuse checkFieldAccessForInternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression fieldAccess) {	
	if (fieldAccess@decl in ctx@declaringTypes) {		    		
		loc declaringType = ctx@declaringTypes[fieldAccess@decl];
		bool isInternalReuse = (<methodDeclaringType, declaringType> in ctx@allInheritance);	
    	if (isInternalReuse) {	
			return reuse(<methodDeclaringType, declaringType> in ctx@directInheritance, 
    		fieldAccessed(), methodDeclaringType, declaringType, fieldAccess@src, fieldAccess@decl);
    	}
	}	
	return noReuse();
}

public Reuse checkSimpleNameForInternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression simpleName) {
	loc declaration = simpleName@decl;
	if (declaration.scheme == "java+field" && declaration in ctx@declaringTypes) {
		loc declaringType = ctx@declaringTypes[declaration];
		bool isInheritance = (<methodDeclaringType, declaringType> in ctx@allInheritance);
		if (isInheritance) {	
			return reuse(<methodDeclaringType, declaringType> in ctx@directInheritance, 
			fieldAccessed(), methodDeclaringType, declaringType, simpleName@src, declaration);
		}
	}
	return noReuse();
}

public Reuse checkCallForInternalReuse(InheritanceContext ctx, Expression methodCall, loc methodDeclaringType) {
	loc calledMethodDeclaration = methodCall@decl;
	if (calledMethodDeclaration in ctx@declaringTypes) {
    	loc calledType = ctx@declaringTypes[calledMethodDeclaration];
		bool isInheritance = (<methodDeclaringType, calledType> in ctx@allInheritance);
		if (isInheritance) {	
			return reuse(<methodDeclaringType, calledType> in ctx@directInheritance, 
			methodCalled(), methodDeclaringType, calledType, methodCall@src, calledMethodDeclaration);
		} 
	}
	return noReuse();
}
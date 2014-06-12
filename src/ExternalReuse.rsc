module ExternalReuse

import Types;						//InheritanceContext
import TypeHelper;					//getDeclarationLoc
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import FileInfo;      				//file loc
import IO;							//save
import List;						//intercalate

public void saveExternalReuse(loc projectLoc, InheritanceContext ctx) { 
	result = for (reuse(bool direct, ReuseSource source, loc from, loc to, loc fromDecl, loc toDecl) <- ctx@externalReuse) 
			 append "<direct>;<source>;<from>;<to>;<fromDecl>";	
	result = ["direct?;source;from;to;from declaration; to declaration"] + result;
	loc fileLoc = defaultOutputPath();
	fileLoc += projectLoc.authority + "-external-reuse.csv";
	writeFile(fileLoc, intercalate("\r\n", result));	
}

public Reuse checkQualifiedNameForExternalReuse(InheritanceContext ctx, Expression qualifier, Expression expression) {
	if (qualifier@decl in ctx@typeMap) {
    	loc variableDeclaringType = getDeclarationLoc(ctx@typeMap[qualifier@decl]);	
    	loc variableUsedType = getDeclarationLoc(qualifier@typ);		
    	if (variableDeclaringType != |type://external| && variableUsedType != |type://external|) {
	    	if (<variableDeclaringType, variableUsedType> in ctx@allInheritance) {
	    		return reuse(<variableDeclaringType, variableUsedType> in ctx@directInheritance, 
									fieldAccessed(), variableDeclaringType, variableUsedType, qualifier@src, expression@decl);
				
	    	}
    	}	
	}
	return noReuse();
}

public Reuse checkFieldAccessForExternalReuse(InheritanceContext ctx, Expression fieldAccess, Expression expr) {
	if (fieldAccess@decl in ctx@declaringTypes) {
		loc declaringType = ctx@declaringTypes[fieldAccess@decl];
		loc expressionDeclaration = getDeclarationLoc(expr@typ);
		loc expressionFieldDeclaration = fieldAccess@decl;
		if (expressionFieldDeclaration in ctx@declaringTypes) {
			loc fieldDeclaringType = ctx@declaringTypes[expressionFieldDeclaration];
			bool isExternalReuse = (<expressionDeclaration, fieldDeclaringType> in ctx@allInheritance);
    		if (isExternalReuse) {				    	
				return reuse(<expressionDeclaration, fieldDeclaringType> in ctx@directInheritance, 
									fieldAccessed(), expressionDeclaration, fieldDeclaringType, fieldAccess@src, fieldAccess@decl);
    		}	
		}
	}		
	return noReuse();
}

public Reuse checkCallForExternalReuse(InheritanceContext ctx, loc methodDeclaringType, Expression methodCall, Expression receiver) {
		loc calledMethodDeclaration = methodCall@decl;
    	if (calledMethodDeclaration in ctx@declaringTypes) {
	    	loc calledType = ctx@declaringTypes[calledMethodDeclaration];
	    	if (methodDeclaringType != calledType) {
				//possible external reuse
				loc receiverType = getDeclarationLoc(receiver@typ);
				if (receiverType != |type://external| && <receiverType, calledType> in ctx@allInheritance) {
					//type of method call receiver is known; declared somewhere in 
					//our code. External reuse
					return reuse(<receiverType, calledType> in ctx@directInheritance, methodCalled(), receiverType, calledType, methodCall@src, calledMethodDeclaration);	
				}
			}	
    	}					
    	return noReuse();
}
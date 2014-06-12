module Constants

import Types;						//InheritanceContext
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import Set;							//size
import IO;

public bool isTypeConstants(InheritanceContext ctx, loc declaration) {
	M3 model = ctx@m3;
	members = model@containment[declaration];
	hasMethods = size({ 1 | m <- members, m.scheme == "java+method"}) > 0;
	if (hasMethods) return false;
	set[Modifier] staticFinal = { static(), final() };
	numberOfConstants = size({f | f <- members, f.scheme == "java+field", staticFinal & model@modifiers[f] == staticFinal });
	numberOfFields = size({f | f <- members, f.scheme == "java+field"});
	return numberOfFields > 0 && (declaration.scheme == "java+interface" || numberOfConstants == numberOfFields);
}
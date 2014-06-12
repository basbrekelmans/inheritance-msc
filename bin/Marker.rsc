module Marker

import Types;						//InheritanceContext
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import FileInfo;      				//file loc
import Set;							//size

public bool isTypeMarker(InheritanceContext ctx, loc declaration) {
	M3 model = ctx@m3;
	members = model@containment[declaration];
	hasMethods = size({ 1 | m <- members, m.scheme == "java+method"}) > 0;
	hasFields = size({f | f <- members, f.scheme == "java+field"}) > 0;
	return !hasMethods && !hasFields;	 
}
module ReuseHelper

import Types;
import TypeHelper;
import Relation;
import lang::java::jdt::m3::Core;	//code analysis
import lang::java::m3::AST;			//code analysis
import IO;

public list[Reuse] getReuse(InheritanceContext ctx, TypeSymbol child, TypeSymbol parent, ReuseSource kind, loc source, loc target) {
		loc childDecl = getDeclarationLoc(child);
		loc parentDecl = getDeclarationLoc(parent);
		if (parent == object()) {
			parentDecl = findHighestParent(ctx, childDecl);
		}
		if (parent == object() || <childDecl, parentDecl> in ctx@allInheritance) {
			set[loc] children = {childDecl}; // invert(ctx@allInheritance)[childDecl] + childDecl;
			return [\reuse(c == childDecl, kind, c, findDirectParent(ctx, c, parentDecl), source, target) | c <- children];
		}
		return [];
}
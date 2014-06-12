module Types

import lang::java::jdt::m3::Core;	//M3
import lang::java::m3::AST;			//Declaration

data InheritanceContext = ctx();
data ReuseSource = fieldAccessed() | methodCalled();
data Reuse = reuse(bool direct, ReuseSource source, loc from, loc to, loc fromDecl, loc toDecl) | noReuse();

data SubtypeSource = typeCasted() | parameterPassed() | varAssigned() | varInitialized() | returned();
data Subtype = subtype(bool direct, SubtypeSource source, loc from, loc to, loc fromDecl) | noSubtype();


anno M3 					InheritanceContext @ m3;
anno map[loc, Declaration]  InheritanceContext @ asts;
anno rel[loc, loc] 		    InheritanceContext @ directInheritance;
anno rel[loc, loc] 		    InheritanceContext @ allInheritance;
anno map[loc, loc] 			InheritanceContext @ declaringTypes;
anno map[loc, TypeSymbol] 	InheritanceContext @ typeMap;
anno list[Reuse] 			InheritanceContext @ externalReuse;
anno list[Reuse] 			InheritanceContext @ internalReuse;
anno list[Subtype] 			InheritanceContext @ subtypes;
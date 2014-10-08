module Types

import lang::java::jdt::m3::Core;	//M3
import lang::java::m3::AST;			//Declaration

data InheritanceContext = ctx();
data ReuseSource = fieldAccessed() | methodCalled();
data Reuse = reuse(bool direct, ReuseSource source, loc from, loc to, loc fromDecl, loc toDecl) | noReuse();

data SubtypeSource = typeCasted() | parameterPassed() | varAssigned() | foreachStatement() | conditional() | varInitialized() | returned() | thisChangingType() | sidewaysCast();
data Subtype = subtype(bool direct, SubtypeSource source, loc from, loc to, loc fromDecl) | noSubtype();

data Downcall = downcall(loc fromType, loc toType, loc fromMethod, loc toMethod, loc calledFrom) | noDowncall();

data Super = super(loc from, loc to, loc fromDecl);
data Generic = generic(loc from, loc to, loc fromDecl) | noGeneric();

anno M3 					InheritanceContext @ m3;
anno map[loc, Declaration]  InheritanceContext @ asts;
anno rel[loc, loc] 		    InheritanceContext @ directInheritance;
anno rel[loc, loc] 		    InheritanceContext @ allInheritance;
anno list[Super] 		    InheritanceContext @ super;
anno set[loc]				InheritanceContext @ typesWithObjectSubtype;
anno list[Generic] 		    InheritanceContext @ generic;
anno rel[loc, loc] 		    InheritanceContext @ invertedOverrides;
anno map[loc, loc] 			InheritanceContext @ declaringTypes;
anno map[loc, TypeSymbol] 	InheritanceContext @ typeMap;
anno list[Reuse] 			InheritanceContext @ externalReuse;
anno list[Reuse] 			InheritanceContext @ internalReuse;
anno list[Subtype] 			InheritanceContext @ subtypes;
anno list[Downcall] 		InheritanceContext @ downcallCandidates;
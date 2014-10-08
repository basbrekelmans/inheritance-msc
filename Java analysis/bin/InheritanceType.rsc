module InheritanceType

import lang::csv::IO; //csv writer
import FileInfo;      //file loc
import IO;			  //print
import Types;	      //context
import Marker;
import Constants;
import TypeHelper;	  //system type?

public void getInheritanceTypes(loc projectLoc, InheritanceContext ctx) {
	print("Writing inheritance types (CC/CI/II)....");
	rel[loc,loc] directInheritance = ctx@directInheritance;
	rel[loc,loc] allInheritance = ctx@allInheritance;
	rel[str \type, loc from, loc to, bool direct, bool marker, bool constants, bool systemType] result = 
	{<getInheritanceType(f, t), f, t, <f,t> in directInheritance, isTypeMarker(ctx, t), isTypeConstants(ctx, t), !isTypeExternal(ctx, t)> | <f,t> <- allInheritance};
	loc fileLoc = defaultOutputPath();
	writeCSV(result, fileLoc + "<projectLoc.authority>-inheritance.csv", ("separator" : ";"));
	println("done");		
}

private str getInheritanceType(loc from, loc to) {
	return ((from.scheme == "java+class" || from.scheme == "java+anonymousClass") ? "C" : "I") + (to.scheme == "java+class" ? "C" : "I");
}
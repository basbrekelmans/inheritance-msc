module ModelCache

import lang::java::jdt::m3::AST;	//createAstsFromEclipseProject
import lang::java::jdt::m3::Core;	//M3 model
import lang::java::m3::AST;			//Declaration
import ValueIO;					    //serialization
import IO;							//file checking
import FileInfo;					//file locations
import Set;							//size

public M3 getM3(loc projectLoc, bool forceRefresh) {
	loc baseLoc = defaultStoragePath();
	loc fileLoc = baseLoc + (projectLoc.authority + ".m3");
	if (forceRefresh || !exists(fileLoc)) {
		print("Creating M3 and saving to disk....");
		M3 model = createM3FromEclipseProject(projectLoc);
		println("done");
		///print("Adding JAR relations...");
		///model = includeJarRelations(model);
		///println("done");
		writeBinaryValueFile(fileLoc, model);
		return model;
	} else {		
		print("Loading M3 from disk....");
		M3 model = readBinaryValueFile(#M3, fileLoc);
		println("done");
		return model;
	}
}


public map[loc, Declaration] getAsts(loc projectLoc, bool forceRefresh) {
	loc baseLoc = defaultStoragePath();
	loc fileLoc = baseLoc + (projectLoc.authority + ".ast");
	if (forceRefresh || !exists(fileLoc)) {
		print("Creating AST and saving to disk....");
		map[loc, Declaration] asts = createAstMap(projectLoc);
		writeBinaryValueFile(fileLoc, asts);
		println("done");
		return asts;
	} else {		
		print("Loading AST from disk....");
		map[loc, Declaration] asts = readBinaryValueFile(#map[loc, Declaration], fileLoc);
		println("done");
		return asts;
	}	
}

private map[loc, Declaration] createAstMap(loc projectLoc) {
	set[Declaration] declarations = createAstsFromEclipseProject(projectLoc, true);
	map[loc, Declaration] output = ();
	for (decl <- declarations) {
		visit(decl) {
		    case Declaration decl: \field(Type \type, list[Expression] fragments): output += (decl@src: decl);	
		    case Declaration decl: \initializer(Statement initializerBody):  output += (decl@decl: decl);
		    case Declaration decl: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):  output += (decl@decl: decl);
		    case Declaration decl: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):  output += (decl@decl: decl);
		    case Declaration decl: \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):  output += (decl@decl: decl);
		}
	}
	return output;
}
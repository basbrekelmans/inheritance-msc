module ModelCache

import util::Resources;
import lang::java::jdt::m3::AST;	//createAstsFromEclipseProject
import lang::java::jdt::m3::Core;	//M3 model
import lang::java::m3::AST;			//Declaration
import ValueIO;					    //serialization
import IO;							//file checking
import FileInfo;					//file locations
import Set;							//size


public void preloadPreviousFailures(bool forceRefresh = false) {
	set[loc] failedProjects = readBinaryValueFile(#set[loc], baseLoc + "failedProjects.locset");
	preloadProjects(failedProjects, forceRefresh);
}

public void preloadAll(bool forceRefresh = false) {
	preloadProjects(projects(), forceRefresh);
}

public void preloadProjects(set[loc] ps, bool forceRefresh) {
    loc baseLoc = defaultStoragePath();
	set[loc] failedProjects = {};
	if (exists(baseLoc +  "failedProjects.locset"))	
		failedProjects = readBinaryValueFile(#set[loc], baseLoc + "failedProjects.locset");	
    set[loc] done = {};
	if (exists(baseLoc + "done.locset"))
		done = readBinaryValueFile(#set[loc], baseLoc + "done.locset");
	ps -= done;
	ps -= failedProjects;
	println("Loading <size(ps)> projects");
	int i = 0;
	for (p <- ps) {
		i = i + 1;
		if (p.authority in { "eclipse-3.7.1", "jdk-1.6.0" })
		{
			println("Skipping <p.authority>...");
			continue;
		}
		try {
			print("<i>/<size(ps)>: <p.authority>...");
			loc fileLoc = baseLoc + (p.authority + ".m3");
			if (exists(fileLoc)) {
				print("m3 exists...");
			} else {
				print("m3...");
				getM3(p, forceRefresh);
			}
			fileLoc = baseLoc + (p.authority + ".ast");
			if (exists(fileLoc)) {
				print("ast exists...");
			} else {
				print("ast...");
				getAsts(p, forceRefresh);
			}
			done += p;
		    writeBinaryValueFile(baseLoc + "done.locset", done);
				println("ok");	
	
		} catch error: {
			println("error!!!");
			println(error);
			failedProjects += p;
			writeBinaryValueFile(baseLoc + "failedProjects.locset", failedProjects);	
		}
	}
	
	writeBinaryValueFile(baseLoc + "failedProjects.locset", failedProjects);	
	println("<size(failedProjects)> projects failed:");
	for (f <- failedProjects) println(f);
	
}


public M3 getM3(loc projectLoc, bool forceRefresh, bool print = false) {
	loc baseLoc = defaultStoragePath();
	loc fileLoc = baseLoc + (projectLoc.authority + ".m3");
	if (forceRefresh || !exists(fileLoc)) {
		if (print)
			print("Creating M3 and saving to disk....");
		M3 model = createM3FromEclipseProject(projectLoc);
		model@messages = [];
		if (print)
			println("done");
		///print("Adding JAR relations...");
		///model = includeJarRelations(model);
		///println("done");
		writeBinaryValueFile(fileLoc, model);
		return model;
	} else {		
		if (print)
		print("Loading M3 from disk....");
		M3 model = readBinaryValueFile(#M3, fileLoc);
		if (print)
		println("done");
		return model;
	}
}


public map[loc, Declaration] getAsts(loc projectLoc, bool forceRefresh, bool print = false) {
	loc baseLoc = defaultStoragePath();
	loc fileLoc = baseLoc + (projectLoc.authority + ".ast");
	if (forceRefresh || !exists(fileLoc)) {
		if (print)
			print("Creating AST and saving to disk....");
		map[loc, Declaration] asts = createAstMap(projectLoc);
		writeBinaryValueFile(fileLoc, asts);
		if (print)
		println("done");
		return asts;
	} else {		
		if (print)
			print("Loading AST from disk....");
		map[loc, Declaration] asts = readBinaryValueFile(#map[loc, Declaration], fileLoc);
		if (print)
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
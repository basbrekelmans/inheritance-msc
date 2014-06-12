module FileInfo

public loc defaultOutputPath() {
	return baseFileLoc() + "Output";
}

public loc defaultStoragePath() {
	return baseFileLoc() + "ModelCache";
}

private loc baseFileLoc() {
	return |file:///C:/InheritanceTest/|;
}

properties {
	$baseDir = resolve-path .
	$projectName = "MyProject"
	
	$databaseServerName = "(local)\sqlexpress"
	$databaseName = "VersionControlSample"
	
	$databaseScriptsPath = "$baseDir\database\mssql\$projectName\DatabaseObjects"
	
	$dbDeployExec = "$baseDir\lib\dbdeploy\dbdeploy.exe"
	$7zipExec = "$baseDir\lib\7zip\7za.exe"
	$nunitRunnerExec = "$baseDir\src\packages\NUnit.Runners.2.6.0.12051\tools\nunit-console.exe"
	
	$standardDatabaseObjectsFolder = "$baseDir\database\mssql\$projectName\StandardObjects"
	$testDataFolder = "$baseDir\database\mssql\$projectName\TestData"
	
	$packagePath = "$baseDir\package"

	$doDatabaseScriptPath = "$packagePath\DatabaseUpgrade.sql"
	$undoDatabaseScriptPath = "$packagePath\DatabaseRollback.sql"
	
	$dateStamp = get-date -uformat "%Y%m%d%H%M"
	
	$testsSolutionFile = "$baseDir\src\DatabaseTests.sln"

	$devDatabaseName = "VersionControlSampleDev"
	$stgDatabaseName = "VersionControlSampleStg"
	$prdDatabaseName = "VersionControlSamplePrd"
}

task default -depends Init, ResetDatabase, PopulateTestData, BuildTests, RunTests, PackageForDev, PackageForStg, PackageForPrd

formatTaskName {
	param($taskName)
	write-host "********************** $taskName **********************" -foregroundcolor Green
}

task Init {
	DeleteAndRecreateFolder $packagePath
}

task ResetDatabase {
	DropSqlDatabase $databaseServerName $databaseName
	CreateSqlDatabase $databaseServerName $databaseName
	RunDatabaseScriptsFromFolder $databaseServerName $databaseName $standardDatabaseObjectsFolder
	Exec { &$dbDeployExec `
		-scriptfiles $databaseScriptsPath `
		-dofile $doDatabaseScriptPath `
		-undofile $undoDatabaseScriptPath `
		-connection "Initial Catalog=$databaseName;Data Source=$databaseServerName;Integrated Security=SSPI;" `
		-type mssql `
		-deltaset $projectName `
		-tablename DatabaseVersion
	}
	ExecuteSqlFile $databaseServerName $databaseName $doDatabaseScriptPath
}

task PopulateTestData {
	RunDatabaseScriptsFromFolder $databaseServerName $databaseName $testDataFolder
}

task BuildTests {
	Exec { msbuild "$testsSolutionFile" /t:Clean /p:Configuration=Release /v:quiet }
	Exec { msbuild "$testsSolutionFile" /t:Build /p:Configuration=Release /v:quiet /p:OutDir="$packagePath\DatabaseTests\" }
}

task RunTests {
	Exec { &$nunitRunnerExec "$packagePath\DatabaseTests\DatabaseTests.dll" /xml="$packagePath\DatabaseTests.dll.xml" }
}

task PackageForDev {
	CreateEnviornmentDoAndUndoSqlFile "Development" $devDatabaseName
	ZipSqlFilesForEnv "Development"
}

task PackageForStg {
	CreateEnviornmentDoAndUndoSqlFile "Staging" $stgDatabaseName
	ZipSqlFilesForEnv "Staging"
}

task PackageForPrd {
	CreateEnviornmentDoAndUndoSqlFile "Production" $prdDatabaseName
	ZipSqlFilesForEnv "Production"
}

# *******************************************************************************
# *******************************************************************************
# *******************************************************************************

Function CreateEnviornmentDoAndUndoSqlFile([string] $env, [string] $databaseName) {
	$envDoScript = $doDatabaseScriptPath.Replace(".sql", "_$env.sql")
	copy-item "$doDatabaseScriptPath" "$envDoScript"
	
	PlaceUsingOnSqlFile $envDoScript $databaseName

	$envUndoScript = $undoDatabaseScriptPath.Replace(".sql", "_$env.sql")
	copy-item "$undoDatabaseScriptPath" "$envUndoScript"

	PlaceUsingOnSqlFile $envUndoScript $databaseName
}

Function ZipSqlFilesForEnv([string] $env) {
	Exec { &$7zipExec a "-x!*.zip" "$packagePath\VersionSample_Database_$env`_$dateStamp.Implement.zip" "$packagePath\DatabaseUpgrade_$env.sql" }
	Exec { &$7zipExec a "-x!*.zip" "$packagePath\VersionSample_Database_$env`_$dateStamp.ROLLBACK.zip" "$packagePath\DatabaseRollback_$env.sql" }
}

Function DeleteAndRecreateFolder($folder) {
	Write-Host "Deleting and recreating $folder."

	if (Test-Path $folder) {
		rd $folder -rec -force | out-null
	}

	mkdir $folder | out-null
}


Function ChangeLinkedServerReference([string] $filePath, [string] $env)
{
    (Get-Content $filePath) `
        | ForEach-object {$_ -replace "-PRD", "-$env" } `
        | ForEach-object {$_ -replace "-STG", "-$env" } `
        | ForEach-object {$_ -replace "-DEV", "-$env" } `
        | Set-Content $filePath
}

Function PlaceUsingOnSqlFile($fullFilePath, [string] $databaseName)
{
    Write-Host "Adding USING [$databaseName] to $fullFilePath"
	
	$isFirst = $true
	
	(Get-Content $fullFilePath) | `
		Foreach-Object {
			if ($isFirst)
			{
				$isFirst = $false
				"USE [$databaseName]"
				"GO"
				""
			}
		
			$_
		} | Set-Content $fullFilePath
}

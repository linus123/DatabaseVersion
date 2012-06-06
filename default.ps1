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

Function RunDatabaseScriptsFromFolder([string]$serverName, [string]$databaseName, [string]$databaseDirectory) {
	$files = Get-ChildItem "$databaseDirectory\*.sql"

	foreach ($file in $files)
	{
		$fileName = $file.name
		Write-Host "Applying script: $fileName"
		
		$fileContents = Get-Content "$file"
		$sql = [string]::Join([Environment]::NewLine, $fileContents);
		ExecuteSqlQuery $serverName $databaseName $sql
	}
}

Function ExecuteSqlFile([string]$serverName, [string]$databaseName, [string]$filePath) {
	Write-Host "Applying script $filePath on server $serverName database $databaseName"
	
	$fileContents = Get-Content "$filePath"
	$sql = [string]::Join([Environment]::NewLine, $fileContents);
	ExecuteSqlQuery $serverName $databaseName $sql
}

Function ExecuteSqlQuery([string]$serverName, [string]$databaseName, [string]$sql) {
	$null = [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
	$null = [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum")
	$null = [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	
	$Server = new-object Microsoft.SqlServer.Management.Smo.Server($serverName)
	$db = $server.Databases[$databaseName]
	Try
	{
		$db.ExecuteNonQuery($sql)
	}
	Catch [system.exception]
	{
		Resolve-Error $_.Exception
		throw
	}
}

Function CreateSqlDatabase([string] $serverName, [string] $databaseName) {
	Write-Host "Attempting to create database $databaseName on server $serverName"

	Try{

		$database = New-Object ('Microsoft.SqlServer.Management.Smo.Database') -argumentlist $serverName,$databaseName
		$database.Create()

	}
	Catch [system.exception] {
		ResolveError $_.Exception
		throw
	}
	
}

Function DropSqlDatabase([string] $serverName, [string] $databaseName) {
	Write-Host "Attempting to drop database $databaseName on server $serverName"
	
	Try{
	
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
		$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $serverName
		
		if ($SMOserver.Databases[$databaseName] -ne $null) {
			Write-Host "Killing all processes on datbase $databaseName."
			$SMOserver.KillAllProcesses($databaseName)
			
			Write-Host "Dropping database $databaseName."
			$SMOserver.Databases[$databaseName].drop()  
		}
		else {
			Write-Host "$databaseName does not exist."
		}

	}
	Catch [system.exception] {
		ResolveError $_.Exception
		throw
	}
}

function ResolveError($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
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

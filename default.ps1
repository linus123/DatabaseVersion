properties {
	$baseDir = resolve-path .
	$projectName = "MyProject"
	
	$databaseServerName = "(local)\sqlexpress"
	$databaseName = "VersionControlSample"
	
	$databaseScriptsPath = "$baseDir\database\mssql\$projectName\TransitionsScripts"
	
	$dbDeployExec = "$baseDir\lib\dbdeploy\dbdeploy.exe"
	$7zipExec = "$baseDir\lib\7zip\7za.exe"
	$nunitRunnerExec = "$baseDir\src\packages\NUnit.Runners.2.6.0.12051\tools\nunit-console.exe"
	
	$standardDatabaseObjectsFolder = "$baseDir\database\mssql\$projectName\StandardObjects"
	$testDataFolder = "$baseDir\database\mssql\$projectName\TestData"
	$versioningScriptsFolder = "$baseDir\database\mssql\$projectName\VersioningScripts"
	
	$packagePath = "$baseDir\package"

	$doDatabaseScriptPath = "$packagePath\DatabaseUpgrade.sql"
	$undoDatabaseScriptPath = "$packagePath\DatabaseRollback.sql"
	
	$dateStamp = get-date -uformat "%Y%m%d%H%M"
	
	$testsSolutionFile = "$baseDir\src\DatabaseTests.sln"

	$devDatabaseName = "VersionControlSampleDev"
	$stgDatabaseName = "VersionControlSampleStg"
	$prdDatabaseName = "VersionControlSamplePrd"
}

task default -depends Init, ResetDatabase, PopulateTestData, BuildTests, RunTests, UpdateVersioningScripts, PackageForDev, PackageForStg, PackageForPrd

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

task UpdateVersioningScripts -depends RunTests {
	DeleteAndRecreateFolder "$baseDir\database\mssql\$projectName\VersioningScripts"

	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMOExtended")| Out-Null;

	$server = $databaseServerName
	$dbname = $databaseName
	$filepath = $versioningScriptsFolder

	$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $server
	$db = $SMOserver.databases[$dbname]

	$Objects = $db.Tables
	$Objects += $db.Views
	$Objects += $db.StoredProcedures
	$Objects += $db.UserDefinedFunctions

	New-Item -Path ($filepath) -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'General') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Analytics') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Cash') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Portfolio') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Price') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Broker') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Benchmark') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Security') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Holding') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Trade') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'General') -ItemType directory -Force | Out-Null
	New-Item -Path ($filepath + "\" + 'Unclassified') -ItemType directory -Force | Out-Null
	
	Write-Host "Iterating database object types"
	
	foreach ($ScriptThis in $Objects | where {!($_.IsSystemObject)}) 
	{
		$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
		$scriptr.Options.ScriptDrops = $true
		$scriptr.Options.IncludeIfNotExists = $true
		$scriptr.Options.DriPrimaryKey = $true
		$scriptr.Options.DriChecks = $true
		$scriptr.Options.DriClustered = $true
		$scriptr.Options.DriDefaults = $true
		$scriptr.Options.DriIndexes = $ture
		$scriptr.Options.DriUniqueKeys = $true
		$scriptr.Options.ExtendedProperties = $true
		$scriptr.Options.Triggers = $true
		$scriptr.Options.Indexes = $true
		$scriptr.Options.ScriptBatchTerminator = $true
		$scriptr.Options.EnforceScriptingOptions = $true
		$scriptr.Options.DriChecks = $true
		$scriptr.Options.AppendToFile = $False
		$scriptr.Options.AllowSystemObjects = $False
		$scriptr.Options.ClusteredIndexes = $True
		$scriptr.Options.DriForeignKeys = $False
		$scriptr.Options.ScriptDrops = $False
		$scriptr.Options.IncludeHeaders = $True
		$scriptr.Options.ToFileOnly = $True
		$scriptr.Options.Indexes = $True
		$scriptr.Options.WithDependencies = $False
		$scriptr.Options.ChangeTracking = $True
		$scriptr.Options.DriIndexes = $true
		$scriptr.Options.SchemaQualify = $true
		$scriptr.Options.IncludeDatabaseContext = $true
		  
		$description = "Unclassified"
						
		If($ScriptThis.ExtendedProperties -ne $null)
		{
			foreach($property in $ScriptThis.ExtendedProperties) 
			{ 
				if($property.Name -eq "Bucket") 
				{ 
					$description = $property.Value; 
				} 
			} 
		}
		  
		$ScriptFile = $ScriptThis -replace "\[|\]"
		$scriptr.Options.FileName = $filepath + "\" + $($description) + "\" + $($ScriptFile) + "_" + $($ScriptThis.GetType().Name) + ".sql"

		$scriptr.Script($ScriptThis)

	}


	$dbObjCollection = @();
	foreach($tb in $db.Tables)
	{
		$dbObjCollection += $tb.ForeignKeys
	}

	foreach ($dbObj in $dbObjCollection) 
	{   
		$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
		$scriptr.Options.DriForeignKeys = $true
		$scriptr.Options.SchemaQualifyForeignKeysReferences = $true
		$scriptr.Options.ScriptBatchTerminator = $true
		$scriptr.Options.ToFileOnly = $true
		$scriptr.Options.SchemaQualify = $true
		$scriptr.Options.ExtendedProperties = $true
		$scriptr.Options.EnforceScriptingOptions = $true
		$scriptr.Options.ChangeTracking = $True
		$scriptr.Options.SchemaQualify = $true
		$scriptr.Options.IncludeDatabaseContext = $true
		
		$smoObjects = @();
		$smoObjects += $dbObj.Urn; 
		if ($dbObj.IsSystemObject -eq $true) 
		{ 
			$sc = $scripter.EnumScript($smoObjects)
		} 
		
		$description = "Unclassified"
						
		If($dbObj.ExtendedProperties -ne $null)
		{
			foreach($property in $ScriptThis.ExtendedProperties) 
			{ 
				if($property.Name -eq "Bucket") 
				{ 
					$description = $property.Value
				} 
			} 
		}

		$scriptr.Options.FileName = $filepath + "\" + $($description) + "\" + $($dbObj.Name) + "_ForeignKey" + ".sql"
		$scriptr.Script($dbObj)
	}
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

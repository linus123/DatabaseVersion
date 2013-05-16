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
		################################################################################################################################
		#
		# Script Name : SmoDb
		# Version     : 1.0
		# Author      : Vince Panuccio
		# Purpose     :
		#			  This script generates one SQL script per database object including Stored Procedures,Tables,Views, 
		#			  User Defined Functions and User Defined Table Types. Useful for versionining a databsae in a CVS.
		#
		# Usage       : 
		#			  Set variables at the top of the script then execute.
		#
		# Note        :
		#			  Only tested on SQL Server 2008r2
		#                 
		################################################################################################################################
		$server 			= $databaseServerName
		$database 			= $databaseName
		$output_path 		= $versioningScriptsFolder
		 
		$schema 			= "dbo"
		$table_path 		= "$output_path\Table\"
		$storedProcs_path 	= "$output_path\StoredProcedure\"
		$views_path 		= "$output_path\View\"
		$udfs_path 			= "$output_path\UserDefinedFunction\"
		$textCatalog_path 	= "$output_path\FullTextCatalog\"
		$udtts_path 		= "$output_path\UserDefinedTableTypes\"
		 
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
		 
		$srv 		= New-Object "Microsoft.SqlServer.Management.SMO.Server" $server
		$db 		= New-Object ("Microsoft.SqlServer.Management.SMO.Database")
		$tbl 		= New-Object ("Microsoft.SqlServer.Management.SMO.Table")
		$scripter 	= New-Object ("Microsoft.SqlServer.Management.SMO.Scripter") ($server)
		 
		# Get the database and table objects
		$db = $srv.Databases[$database]
		 
		$tbl		 	= $db.tables | Where-object { $_.schema -eq $schema  -and -not $_.IsSystemObject } 
		$storedProcs	= $db.StoredProcedures | Where-object { $_.schema -eq $schema -and -not $_.IsSystemObject } 
		$views 		 	= $db.Views | Where-object { $_.schema -eq $schema } 
		$udfs		 	= $db.UserDefinedFunctions | Where-object { $_.schema -eq $schema -and -not $_.IsSystemObject } 
		$catlog		 	= $db.FullTextCatalogs
		$udtts		 	= $db.UserDefinedTableTypes | Where-object { $_.schema -eq $schema } 
			
		# Set scripter options to ensure only data is scripted
		$scripter.Options.ScriptSchema 	= $true;
		$scripter.Options.ScriptData 	= $false;
		 
		#Exclude GOs after every line
		$scripter.Options.NoCommandTerminator 	= $false;
		$scripter.Options.ToFileOnly 			= $true
		$scripter.Options.AllowSystemObjects 	= $false
		$scripter.Options.Permissions 			= $true
		$scripter.Options.DriAllConstraints 	= $true
		$scripter.Options.SchemaQualify 		= $true
		$scripter.Options.AnsiFile 				= $true
		 
		$scripter.Options.SchemaQualifyForeignKeysReferences = $true
		 
		$scripter.Options.Indexes 				= $true
		$scripter.Options.DriIndexes 			= $true
		$scripter.Options.DriClustered 			= $true
		$scripter.Options.DriNonClustered 		= $true
		$scripter.Options.NonClusteredIndexes 	= $true
		$scripter.Options.ClusteredIndexes 		= $true
		$scripter.Options.FullTextIndexes 		= $true
		 
		$scripter.Options.EnforceScriptingOptions 	= $true
		 
		function CopyObjectsToFiles($objects, $outDir) {
			
			if (-not (Test-Path $outDir)) {
				[System.IO.Directory]::CreateDirectory($outDir)
			}
			
			foreach ($o in $objects) { 
			
				if ($o -ne $null) {
					
					$schemaPrefix = ""
					
					if ($o.Schema -ne $null -and $o.Schema -ne "") {
						$schemaPrefix = $o.Schema + "."
					}
				
					$scripter.Options.FileName = $outDir + $schemaPrefix + $o.Name + ".sql"
					Write-Host "Writing " $scripter.Options.FileName
					$scripter.EnumScript($o)
				}
			}
		}
		 
		# Output the scripts
		CopyObjectsToFiles $tbl $table_path
		CopyObjectsToFiles $storedProcs $storedProcs_path
		CopyObjectsToFiles $views $views_path
		CopyObjectsToFiles $catlog $textCatalog_path
		CopyObjectsToFiles $udtts $udtts_path
		CopyObjectsToFiles $udfs $udfs_path
		 
		Write-Host "Finished at" (Get-Date)
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

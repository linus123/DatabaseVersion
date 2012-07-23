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
		ResolveError $_.Exception
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

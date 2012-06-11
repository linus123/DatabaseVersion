Database Versioning Sample
================================

Overview
--------------------------------
This is an example of a simple / free method to version an MS-SQL database.  It includes methods for roll forward/roll back scripting, static test data, and database unit testing.

Important Note
--------------------------------
This project assumes that you have SQL Express and SQL Server Management tools installed on your local computer.  SQL Express must be running on the default install instance: (local)\sqlexpress

How to Run
--------------------------------
Check out the code to your local computer and run...

    ClickToBuild.bat
	
Powershell Message
--------------------------------
The first time you run a PowerShell module on your computer you may get an error message complaining about execution policies.  PowerShell security by default will not run is set to NOT run modules.  You can solve the problem by running PowerShell as an administrator and typing in the command

	Set-ExecutionPolicy RemoteSigned
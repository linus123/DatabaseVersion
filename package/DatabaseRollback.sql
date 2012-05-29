-- Script generated at 2012-05-28T10:24:33



--------------- Fragment begins: #2: 002_CreatePaycheckTable.sql ---------------

-- Change script: #2: 002_CreatePaycheckTable.sql

DROP TABLE [dbo].[Paycheck]

DELETE FROM DatabaseVersion WHERE change_number = 2 AND delta_set = 'MyProject'
GO

--------------- Fragment ends: #2: 002_CreatePaycheckTable.sql ---------------

--------------- Fragment begins: #1: 001_CreateEmployeeTable.sql ---------------

-- Change script: #1: 001_CreateEmployeeTable.sql

DROP TABLE [dbo].[Employee]

DELETE FROM DatabaseVersion WHERE change_number = 1 AND delta_set = 'MyProject'
GO

--------------- Fragment ends: #1: 001_CreateEmployeeTable.sql ---------------

USE [VersionControlSample]
GO
/****** Object:  View [dbo].[vw_EmployeeLastPaycheck]    Script Date: 5/21/2013 12:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_EmployeeLastPaycheck]'))
EXEC dbo.sp_executesql @statement = N'

-- Change script: #30: 0030_CreateEmployeeLastPaycheckView.sql
CREATE VIEW [dbo].[vw_EmployeeLastPaycheck]
AS

SELECT
		Employee.EmployeeId
		, Employee.FirstName
		, Employee.LastName
		, Employee.CityState
		, Paycheck.PaycheckNumber
		, Paycheck.Amount
	FROM
		Employee
		INNER JOIN Paycheck ON
		(
			Employee.EmployeeId = Paycheck.EmployeeId
		)
		INNER JOIN
		(
			SELECT
				Paycheck.EmployeeId,
				MAX(Paycheck.PaycheckNumber) AS MaxPaycheckNumber
			FROM
				Paycheck
			GROUP BY
				Paycheck.EmployeeId
		) AS MaxPaycheck ON
		(
			Paycheck.PaycheckNumber = MaxPaycheck.MaxPaycheckNumber
		)
		


' 
GO

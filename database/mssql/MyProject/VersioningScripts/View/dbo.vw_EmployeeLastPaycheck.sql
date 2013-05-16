SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


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
		



GO

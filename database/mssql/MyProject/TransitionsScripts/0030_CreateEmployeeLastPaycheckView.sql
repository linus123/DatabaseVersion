CREATE VIEW vw_EmployeeLastPaycheck
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
		

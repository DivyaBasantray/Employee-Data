SELECT * 
FROM employee_data;

SELECT DepartmentType, ROUND(AVG(Desired_Salary), 2) AS avg_salary
FROM employee_data AS e
INNER JOIN recruitment_data AS r
ON e.EmpID = r.Applicant_ID
WHERE EmployeeStatus = 'Active'
GROUP BY DepartmentType
order by DepartmentType;

SELECT *
FROM (
	SELECT EmpID, FirstName +' '+ LastName AS FullName,  DepartmentType,
	RANK() OVER(PARTITION BY DepartmentType ORDER BY Current_Employee_Rating DESC, firstName, lastName) AS rnk
	FROM employee_data 
)a
WHERE rnk = 1;

SELECT DISTINCT DepartmentType,
MAX(Current_Employee_Rating) OVER(PARTITION BY DepartmentType) AS maxPerformanceRating
FROM employee_data;

SELECT EmpID, FirstName +' '+ LastName AS FullName, Current_Employee_Rating
FROM employee_data 
WHERE DepartmentType = 'IT/IS' AND Current_Employee_Rating > 3
ORDER BY FullName;

SELECT EmpID, FirstName +' '+ LastName AS FullName,
DepartmentType, ROUND(Desired_Salary, 2) AS Desired_Salary,
DENSE_RANK() OVER(PARTITION BY DepartmentType ORDER BY ROUND(Desired_Salary, 2) DESC) AS salaryRank
FROM employee_data AS e
INNER JOIN recruitment_data AS r
ON e.EmpID = r.Applicant_ID
WHERE EmployeeStatus = 'Active';

SELECT COUNT(*)
FROM employee_data
WHERE YEAR(ExitDate) = '2023';

SELECT Supervisor, COUNT(*) AS Juniors
FROM employee_data
GROUP BY Supervisor
ORDER BY COUNT(*) DESC;

SELECT EmployeeType, COUNT(*) AS total
FROM employee_data
GROUP BY EmployeeType
ORDER BY EmployeeType;

SELECT GenderCode, COUNT(*) AS total
FROM employee_data
GROUP BY GenderCode;

SELECT Division, COUNT(*) AS total
FROM employee_data
WHERE EmployeeStatus = 'Active' AND ExitDate IS NULL
GROUP BY Division
ORDER BY COUNT(*) DESC;

SELECT RaceDesc, COUNT(*) AS total
FROM employee_data
WHERE ExitDate IS NULL
GROUP BY RaceDesc;

SELECT FirstName + ' ' + LastName AS Name, StartDate, ExitDate,
DATEDIFF(YEAR, StartDate, COALESCE( ExitDate, CONVERT(DATE, getDate()) )) AS 'tenure(years)'
FROM employee_data;

ALTER TABLE employee_data
ADD tenure INT;

UPDATE employee_data
SET tenure = DATEDIFF(YEAR, StartDate, COALESCE( ExitDate, CONVERT(DATE getDate()) ));

SELECT StartDate, ExitDate, tenure 
FROM employee_data;

SELECT SeniorityLevel, COUNT(*) AS total
FROM (
	SELECT *,
	CASE WHEN DATEDIFF(YEAR, StartDate, COALESCE( ExitDate, CONVERT(DATE, getDate()) )) <= 5 
    THEN 'Junior' ELSE 'Senior' END AS SeniorityLevel
	FROM employee_data
)a
WHERE a.ExitDate IS NULL AND a.EmployeeStatus = 'Active'
GROUP BY a.SeniorityLevel;

SELECT DepartmentType, Division, COUNT(*) AS total
FROM employee_data
GROUP BY DepartmentType, Division
ORDER BY DepartmentType, Division;

SELECT DepartmentType, Division, COUNT(*) AS total
FROM employee_data
WHERE Division = 'Engineers' AND EmployeeStatus = 'Active'
GROUP BY DepartmentType, Division
ORDER BY COUNT(*) DESC;

SELECT * 
FROM employee_data;

WITH cte AS (
	SELECT Performance_Score, COUNT(*) AS total
	FROM employee_data
	WHERE ExitDate IS NULL
	GROUP BY Performance_Score
)
SELECT *,
(total*100/(SELECT SUM(total) FROM cte)) AS 'percentage'
FROM cte;

-- 86 employees need improvement while 44 are currently under Performance imporovement plan (pip)
-- selecting those people from pip

SELECT *
FROM employee_data
WHERE Performance_Score = 'PIP' AND ExitDate IS NULL;

WITH pivotTable AS 
(
	SELECT EmployeeClassificationType, [Active],[Future Start], [Leave of Absence], [Terminated for Cause], [Voluntarily Terminated],
	([Active]+[Future Start]+[Leave of Absence]+[Terminated for Cause]+[Voluntarily Terminated]) AS total
FROM (
		SELECT EmployeeStatus, EmployeeClassificationType, COUNT(*) AS total
		FROM employee_data
		GROUP BY EmployeeStatus, EmployeeClassificationType
	)a
pivot(
	SUM(total)
	FOR employeeStatus IN ([Active],[Future Start], [Leave of Absence], [Terminated for Cause], [Voluntarily Terminated] )
	) AS pivotTable
)

SELECT * 
FROM pivotTable;

SELECT
COALESCE(EmployeeClassificationType,' Grand Total') AS EmployeeClassificationType,
SUM(Active) Active,
SUM([Future Start]) AS FutureStart,
SUM([Leave of Absence]) AS LeaveOfAbsence,
SUM([Terminated for Cause]) AS TerminatedForCause,
SUM([Voluntarily Terminated]) AS VoluntarilyTerminated,
SUM(total) AS total
FROM pivotTable
GROUP BY EmployeeClassificationType WITH ROLLUP;

SELECT EmpID, FirstName, LastName, StartDate
FROM employee_data
WHERE StartDate = (SELECT MIN(StartDate) FROM employee_data);

SELECT EmpID, FirstName, LastName, StartDate
FROM employee_data
WHERE StartDate = (SELECT MAX(StartDate) FROM employee_data);

SELECT EmpID, FirstName, LastName, StartDate, ExitDate
FROM employee_data
WHERE ExitDate = (SELECT MIN(ExitDate) FROM employee_data);

SELECT Performance_Score, AVG(tenure) AS averageTenure
FROM employee_data
GROUP BY Performance_Score;

SELECT RaceDesc, GenderCode, AVG(Current_Employee_Rating) AS avgPerformanceScore
FROM employee_data 
GROUP BY RaceDesc, GenderCode;

SELECT 
	JobFunctionDescription, COUNT(*) AS 'total',
	CAST(
		(100*COUNT(*)/(SELECT COUNT(*) 
		 FROM employee_data 
		 WHERE Performance_Score='Exceeds')) AS VARCHAR) + '%' AS 'Percentage'
FROM employee_data AS e
WHERE Performance_Score = 'Exceeds'
GROUP BY JobFunctionDescription
ORDER BY 'total' DESC;

SELECT DISTINCT JobFunctionDescription,
COUNT(*) OVER(PARTITION BY JobFunctionDescription) AS 'total'
FROM employee_data
WHERE Performance_Score = 'Exceeds'
ORDER BY total DESC;

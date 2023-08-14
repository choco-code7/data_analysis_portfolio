-- data cleaning --

-- update the data formate and datatype in birthdate column.
UPDATE hr
SET birthdate = CASE
		WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;


-- update the data formate and datatype of hire_date colum
UPDATE hr
SET hire_date = CASE
		WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END;


ALTER TABLE hr
MODIFY COLUMN hire_date DATE;


-- update the date format and datatype of termdate column

UPDATE hr
SET termdate = DATE(STR_TO_DATE(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL
  AND termdate != '';


UPDATE hr
SET termdate = NULL
WHERE termdate = '';

-- create age colum --
ALTER TABLE hr
ADD COLUMN age INT;

UPDATE hr
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());

SELECT MIN(age), max(age) FROM hr;


-- data analyzation --

-- 1 .What is the Gender Breakdown of the Company?

SELECT gender, COUNT(*) AS GenderCount
FROM hr 
WHERE termdate IS NULL
GROUP BY gender;


-- 2 .What is the Race Breakdown of the Company?

SELECT race, COUNT(*) AS RaceCount
FROM hr 
WHERE termdate IS NULL
GROUP BY race;


-- 3 .What is the Age Distribution of Emplouees in the Company?
	
SELECT 
	CASE
		WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
	END AS age_group,
	COUNT(*) AS AgeCategories,
	
	CONCAT( 
			ROUND( 
					( COUNT(*) / SUM( COUNT(*)) OVER ()) * 100, 
					2 
			 ),
			 '%' 
	) AS Percentage
	
FROM hr
WHERE termdate IS NULL
GROUP BY age_group
ORDER BY age_group;

-- 4. How many Employees work at HQ vs Remote?
SELECT location, COUNT(*)AS the_count,
	CONCAT( 
			ROUND( 
					( COUNT(*) / SUM( COUNT(*)) OVER ()) * 100, 
					2 
			 ),
			 '%' 
	) AS Percentage
FROM hr 
WHERE termdate IS NULL
GROUP BY location;


-- 5. What is the Average duration of employement who have been terminated?

SELECT ROUND(AVG(YEAR(termdate) - YEAR(hire_date)),2) AS duration_of_emp
FROM hr
WHERE termdate IS NOT NULL AND termdate <= CURDATE();



SELECT ROUND(AVG(TIMESTAMPDIFF(YEAR, hire_date, termdate)), 2) AS duration_of_emp
FROM hr
WHERE termdate IS NOT NULL AND termdate <= CURDATE();


-- 6. How does the Gender Distribution vary across Dept and Jop Titles ?
SELECT department,jobtitle,gender,COUNT(*) AS count
FROM hr
WHERE termdate IS NOT NULL
GROUP BY department, jobtitle,gender
ORDER BY department, jobtitle,gender


SELECT department,gender,COUNT(*) AS count
FROM hr
WHERE termdate IS NOT NULL
GROUP BY department,gender
ORDER BY department,gender


-- 7. What is the distribution of jobtitles acorss the company
SELECT jobtitle, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY jobtitle


-- .8 Which Department Has the highiest Termination Rate
								
SELECT
    department,
    COUNT(*) AS total_count,
    SUM(termdate IS NOT NULL AND termdate <= CURDATE()) AS termination_count,
    ROUND((SUM(termdate IS NOT NULL AND termdate <= CURDATE()) / COUNT(*)) * 100, 2) AS termination_rate
FROM hr
GROUP BY department
ORDER BY termination_rate DESC;

-- using a temp table

DROP TABLE IF EXISTS temp_hr;
CREATE TEMPORARY TABLE temp_hr AS (
    SELECT
        department,
        COUNT(*) AS total_count,
        SUM(termdate IS NOT NULL AND termdate <= CURDATE()) AS termination_count
    FROM hr
    GROUP BY department
);

SELECT
		*,
    ROUND((termination_count / total_count) * 100, 2) AS termination_rate
FROM temp_hr
ORDER BY termination_rate DESC;

DROP TABLE temp_hr;

-- 9. What is the distribution of employees across location_state
SELECT
    location_state,
    COUNT(*) AS count_of_emp,
    CONCAT(ROUND((COUNT(*) / (SELECT COUNT(*) FROM hr WHERE termdate IS NULL)) * 100, 2), '%') AS percentage
FROM hr
WHERE termdate IS NULL
GROUP BY location_state;


SELECT location_city, 
    COUNT(*) AS count_of_emp,
    CONCAT(ROUND((COUNT(*) / (SELECT COUNT(*) FROM hr WHERE termdate IS NULL)) * 100, 2), '%') AS percentage
FROm hr
WHERE termdate IS NULL
GROUP BY location_city


-- 10. How has the companys employee count changed over time based on hire and termination date.

-- using subquery
SELECT 
				*,
        hires-terminations AS net_change,
       CONCAT(ROUND((terminations / hires) * 100, 2), ' %') AS termination_rate
	FROM(
			SELECT YEAR(hire_date) AS year,
            COUNT(*) AS hires,
            SUM(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hr
            GROUP BY YEAR(hire_date)) AS subquery
GROUP BY year
ORDER BY year;

-- using subquery
WITH subquery AS (
    SELECT YEAR(hire_date) AS year,
           COUNT(*) AS hires,
           SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM hr
    GROUP BY YEAR(hire_date)
)
SELECT 
			 *,
       hires - terminations AS net_change,
       CONCAT(ROUND((terminations / hires) * 100, 2), ' %') AS termination_rate
FROM subquery
ORDER BY year;

-- uisng temp table

DROP TABLE IF EXISTS temp_subquery;
CREATE TEMPORARY TABLE temp_subquery AS (
    SELECT YEAR(hire_date) AS year,
           COUNT(*) AS hires,
           SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM hr
    GROUP BY YEAR(hire_date)
);

SELECT 
			 *,
       hires - terminations AS net_change,
       CONCAT(ROUND((terminations / hires) * 100, 2), '%') AS termination_rate
FROM temp_subquery
ORDER BY year;




-- 11. what is the average of termination rate each year?
SELECT year, ROUND(AVG(hires - terminations)) AS avg_change
FROM temp_subquery
GROUP BY year
ORDER BY avg_change DESC;



-- 12. What is the tenure distribution for each dept.
SELECT department, round(avg(datediff(termdate,hire_date)/365),0) AS avg_tenure
FROM hr
WHERE termdate IS NOT NULL AND termdate<= curdate()
GROUP BY department

-- using CTE 

WITH terminated_employees AS (
  SELECT department, YEAR(termdate) - YEAR(hire_date) AS tenure
  FROM hr
  WHERE termdate IS NOT NULL AND termdate <= CURDATE()
)
SELECT department, ROUND(AVG(tenure), 0) AS avg_tenure
FROM terminated_employees
GROUP BY department;

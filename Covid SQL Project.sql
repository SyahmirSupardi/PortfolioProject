-- Checking Database for further inspect

Select *
From CovidProject..CovidDeaths
order by 3,4

Select *
From CovidProject..CovidVaccinations
order by 3,4

-- Select Data we are going to be using

Select Location, Date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
order by 1,2

-- OBJECTIVE: Focusing on Total Cases vs Total Deaths
	-- ISSUE:
		-- Convert string type to decimal (total_deaths and total_cases stated as string type)
		-- Located specific area (Malaysia)
		-- CASE executed due to some rows had 0 value caused error division

SELECT 
	Location, 
	Date, 
	total_cases, 
	total_deaths,
	CASE
		WHEN total_cases = 0 THEN 0
		ELSE 
			Convert(DECIMAL(18,2), 
			(CONVERT(DECIMAL(18,2), total_deaths) / CONVERT(DECIMAL(18,2), total_cases)) * 100) 
		END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location like '%Malaysia%'
ORDER BY 1,2

-- OBJECTIVE: Focusing on Total Cases vs Population

SELECT 
	Location, 
	Date, 
	total_cases, 
	population,
	CASE
		WHEN total_cases = 0 THEN 0
		ELSE 
			Convert(DECIMAL(18,2), 
			(CONVERT(DECIMAL(18,2), total_cases) / CONVERT(DECIMAL(18,2), population)) * 100) 
		END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location like '%Malaysia%'
ORDER BY 1,2

-- OBJECTIVE: Focusing at countries with Highest Infection Rate compare to Population
	-- ISSUE:
		-- There are non-numeric entries in total_cases
		-- non-numeric in total_cases are showns as " " instead of NULL or 0
		-- By using TRY_CONVERT instead of CONVERT gives any non-numeric values to NULL instead throwing an error
		
		---- Find non-numeric entries in total_cases
			--SELECT Location, total_cases
			--FROM CovidProject..CovidDeaths
			--WHERE ISNUMERIC(total_cases) = 0;

		
SELECT 
    Location, 
    MAX(TRY_CONVERT(DECIMAL(18,2), total_cases)) AS HighestInfectionCount, 
    population,
    CASE
        WHEN MAX(TRY_CONVERT(DECIMAL(18,2),total_cases)) = 0 THEN 0
        ELSE 
            CONVERT(DECIMAL(18,2), 
            (MAX(TRY_CONVERT(DECIMAL(18,2), total_cases)) / CONVERT(DECIMAL(18,2), population)) * 100) 
    END AS PercentagePopulationInfected
FROM 
    CovidProject..CovidDeaths
WHERE
		continent IS NOT NULL
		AND
		continent != ' '
GROUP BY 
    Location, population
ORDER BY 
    Location, HighestInfectionCount desc;


-- OBJECTIVE: Focusing countries with Highest Death Count per Population
	-- ISSUE:
		-- Replacing INT to BIGINT because the value in the data exceeds the integer limit
		-- WHERE function executed to filtered the continent that have ' ' value in CovidDeaths report


SELECT 
    Location, 
    MAX(TRY_CONVERT(BIGINT, total_deaths)) AS TotalDeathCount
FROM
	CovidProject..CovidDeaths
WHERE
		continent IS NOT NULL
		AND
		continent != ' '
GROUP BY
	location
ORDER BY 
	TotalDeathCount desc;



-- OBJECTIVE: Focusing on New Total Cases vs New Total Deaths
	-- ISSUE:
		-- Summing on both new_cases and new_deaths
		-- We handled zero or NULL cases by using CASE statement due some data create errors when no cases returned for the death percentage
		-- Multiply 100.0 before divide new_cases to ensure SQL treats the division as a floating-point operation, avoids truncation to integer

SELECT
    date,
    SUM(CAST(new_cases AS BIGINT)) AS new_total_cases,
    SUM(CAST(new_deaths AS BIGINT)) AS new_total_deaths,
    CASE
        WHEN SUM(CAST(new_cases AS BIGINT)) = 0 OR SUM(CAST(new_cases AS BIGINT)) IS NULL THEN 0
        ELSE (SUM(CAST(new_deaths AS BIGINT)) * 100.0) / SUM(CAST(new_cases AS BIGINT))
    END AS DeathPercentage
FROM
    CovidProject..CovidDeaths
WHERE
    continent IS NOT NULL
    AND continent != ' '
GROUP BY
    date
ORDER BY 
    1,2 DESC;



-- OBJECTIVE: Summary Total Global Death Percentage

SELECT
    SUM(CAST(new_cases AS BIGINT)) AS new_total_cases,
    SUM(CAST(new_deaths AS BIGINT)) AS new_total_deaths,
    CASE
        WHEN SUM(CAST(new_cases AS BIGINT)) = 0 OR SUM(CAST(new_cases AS BIGINT)) IS NULL THEN 0
        ELSE (SUM(CAST(new_deaths AS BIGINT)) * 100.0) / SUM(CAST(new_cases AS BIGINT))
    END AS DeathPercentage
FROM
    CovidProject..CovidDeaths
WHERE
    continent IS NOT NULL
    AND continent != ' '
ORDER BY 
    1,2 DESC;



-- OBJECTIVE: Join both Covid Deaths's data and Covid Vaccination's data

SELECT *
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date



-- OBJECTIVE: Focusing on Total Population vs Vaccination
	-- ISSUE:
		-- some new_vaccinations columns are shown as ' ' instead of NULL
		 ---- We executed NULLIF to replace any ' ' in the data

SELECT 
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	NULLIF(cv.new_vaccinations,' ') AS new_vaccinations,
	SUM(CONVERT(BIGINT,cv.new_vaccinations)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS Rolling_People_Vaccinated
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cv.continent IS NOT NULL
	AND cv.continent != ' '
ORDER BY
	2,3;


-- OBJECTIVE: (CTE Real-Time Tutorial) Focusing on Population vs Vaccinations

WITH PopVac (Continent, Location, Date, Population, new_vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT 
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	NULLIF(cv.new_vaccinations,' ') AS new_vaccinations,
	SUM(CONVERT(BIGINT,cv.new_vaccinations)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS Rolling_People_Vaccinated
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cv.continent IS NOT NULL
	AND cv.continent != ' '
)

SELECT *, (Rolling_People_Vaccinated*100.00/Population) 
FROM PopVac



-- OBJECTIVE: (Temp Table Real-time Tutorial)
	-- ISSUES:
		-- Invalid datetime data from Varchar to datetime conversion
			-- Identify invalid date entries from both CovidDeaths and CovidVaccinations
			
SELECT cd.location, cd.date
FROM CovidProject..CovidDeaths AS cd
WHERE ISDATE(cd.date) = 0;

SELECT cv.location, cv.date
FROM CovidProject..CovidVaccinations AS cv
WHERE ISDATE(cv.date) = 0;

			-- Check date format and fix the query by using TRY_CONVERT or CONVERT function 	

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated

(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT 
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	NULLIF(cv.new_vaccinations,' ') AS new_vaccinations,
	SUM(CONVERT(BIGINT,cv.new_vaccinations)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS Rolling_People_Vaccinated

FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND TRY_CONVERT(DATETIME, cd.date, 121) = TRY_CONVERT(DATETIME, cv.date, 121) --# Query have been fixed
WHERE
	cv.continent IS NOT NULL
	AND cv.continent != ' '

SELECT *, (Rolling_People_Vaccinated*100.00/Population) 
FROM #PercentPopulationVaccinated



-- OBJECTIVE: Creating View to store data for further visualization
	-- ISSUE:
		-- Schema file or creation process is failing, or missing/hidden query in Object Explorer
			---- To troubleshoot this issue, check the view in sys.views

SELECT * 
FROM sys.views 
WHERE name = 'PercentPopulationVaccinated';

			---- Refresh Object Explorer or Restart the SSMS if refresh doesn't worked


CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	NULLIF(cv.new_vaccinations,' ') AS new_vaccinations,
	SUM(CONVERT(BIGINT,cv.new_vaccinations)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS Rolling_People_Vaccinated

FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND TRY_CONVERT(DATETIME, cd.date, 121) = TRY_CONVERT(DATETIME, cv.date, 121) --# Query have been fixed
WHERE
	cv.continent IS NOT NULL
	AND cv.continent != ' '

-- END OF THE QUERY!

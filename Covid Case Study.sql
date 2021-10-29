/*
	THE LATEST COVID CASES, DEATHS, VACCINATIONS, AND SO ON HAVE BEEN CLEANED UP, AND DATA RELATING TO COVID CASES WAS SAVED AS AN EXCEL FILE, 
	WHILE DATA RELATING TO VACCINATIONS WAS SAVED IN ANOTHER EXCEL FILE. THE TWO FIIES WERE COMBINED AND ANALYZED.

	CovidDeaths: Information on COVID cases from around the world. 
	CovidVaccinations: Vaccination data from around the world.
*/

SELECT *
FROM FolioProject..CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- TO DIPLAY JUST THE REQUIRED COLUMNS
SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM FolioProject..CovidDeaths
ORDER BY 1, 2

-- LOOKING AT TOTAL CASES VS TOTAL DEATHS
-- LIKELIHOOD OF CONTRACTING COVID IN YOUR COUNTRY

SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 AS deaths_percentage
FROM FolioProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1, 2

-- TOTAL CASES VS THE POPULATION
-- PERCENTAGE OF POPULATION THAT GOT COVID
SELECT 
	location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 AS cases_percentage
FROM FolioProject..CovidDeaths
WHERE continent IS NOT NULL -- REQUIRED TO DISPLAY COUNTRY WISE DATA RATHER THAN CONTINENT WISE
ORDER BY 1, 2

--COUNTRIES WITH HIGHEST INFECTION RATES COMPARED TO POPULATION

SELECT 
	location, 
	MAX(total_cases) AS highest_per_country, 
	population, 
	MAX(total_cases/population)*100 AS percent_population_affected
FROM 
	FolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	location, 
	population
ORDER BY percent_population_affected DESC

-- COUNTRIES WITH THE HIGHEST DEATH COUNT BY POPULATION

SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS Total_death_count
FROM 
	FolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	location, 
	population
ORDER BY Total_death_count DESC

-- CONTINENTS WITH HIGHEST DEATH COUNT

SELECT 
	continent, 
	MAX(CAST(total_deaths AS INT)) AS Total_death_count
FROM 
	FolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_death_count DESC

--GLOBAL NUMBERS

SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,  
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS deaths_percentage
FROM FolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--LOOKING AT TOTAL POPULATION VS VACCINATION AND GET A CUMULATIVE COUNT OF VACCINATED PEOPLE BY LOCATION AND DATE

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
	FolioProject..CovidDeaths dea
JOIN 
	FolioProject..CovidVaccinations vac
ON 
	dea.location = vac.location AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
ORDER BY
	2, 3

-- USING CTE (Common Table Expressions)

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
	SELECT 
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	FROM 
		FolioProject..CovidDeaths dea
	JOIN 
		FolioProject..CovidVaccinations vac
	ON 
		dea.location = vac.location AND dea.date = vac.date
	WHERE 
		dea.continent IS NOT NULL
)
SELECT 
	*, 
	(Rolling_People_Vaccinated/Population)*100 AS percentage_of_people_vaccinated
FROM PopvsVac



-- TEMP TABLE (SAME FUNCTIONS PERFORMED AS ABOVE)
DROP TABLE IF EXISTS #PercentPopulationVaccination -- ADD WHEN QUERY IS RUN MULTIPLE TIMES ELSE ERROR: TABLE ALREADY EXISTS
CREATE TABLE #PercentPopulationVaccination
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	Rolling_People_Vac numeric
)

INSERT INTO #PercentPopulationVaccination
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	FROM 
		FolioProject..CovidDeaths dea
	JOIN 
		FolioProject..CovidVaccinations vac
	ON 
		dea.location = vac.location AND dea.date = vac.date

SELECT *, (Rolling_People_Vac/Population)*100 AS percentage_of_people_vaccinated
FROM #PercentPopulationVaccination


-- CREATING A VIEW TO STORE DATA FOR LATER

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	FROM 
		FolioProject..CovidDeaths dea
	JOIN 
		FolioProject..CovidVaccinations vac
	ON 
		dea.location = vac.location AND dea.date = vac.date
	WHERE
		dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated

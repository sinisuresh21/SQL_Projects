SELECT * FROM CovidDeaths
--WHERE continent is NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

--Total case Vs Total Deaths

SELECT location, date, total_cases, total_deaths, (1.0*total_deaths/total_cases)*100 AS DeathsPercent
FROM CovidDeaths
WHERE [location] LIKE 'India'
ORDER BY 1,2

--Total cases Vs Population

SELECT location, date, total_cases, population, (1.0*total_cases/population)*1000 AS CovidPercent
FROM CovidDeaths
WHERE [location] LIKE 'India'
ORDER BY 1,2

--Highest infection rate in each location

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((1.0*total_cases/population))*100 AS CovidPercent
FROM CovidDeaths
GROUP BY [location],population
ORDER BY CovidPercent DESC

--Highest death count by location

SELECT location, MAX(total_deaths) AS HighestDeath
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY HighestDeath DESC

--Highest death count by continent

SELECT continent, MAX(total_deaths) AS HighestDeath
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeath DESC

SELECT [location], MAX(total_deaths) AS HighestDeath
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY [location]
ORDER BY HighestDeath DESC

--Global break down

SELECT date, SUM(new_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, 
    (SUM(1.0*new_deaths)/SUM(1.0*new_cases))*100 as new_death_percentage
FROM CovidDeaths
WHERE [continent] IS NOT NULL
GROUP BY [date]
ORDER BY 1,2

SELECT SUM(new_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, 
    (SUM(1.0*new_deaths)/SUM(1.0*new_cases))*100 as death_percentage
FROM CovidDeaths
WHERE [continent] IS NOT NULL
ORDER BY 1,2

-- Total population compared to total vaccination

SELECT cov_dea.continent, cov_dea.[location], cov_dea.[date], cov_dea.population,
    cov_vac.new_vaccinations
FROM CovidDeaths cov_dea
JOIN CovidVaccinations cov_vac
    ON cov_dea.[location] = cov_vac.[location]
    AND cov_dea.[date] = cov_vac.[date]
WHERE cov_dea.continent IS NOT NULL
--AND cov_vac.new_vaccinations IS NOT NULL
ORDER BY 2,3


SELECT cov_dea.continent, cov_dea.[location], cov_dea.[date], cov_dea.population,
    cov_vac.new_vaccinations, 
    SUM(CONVERT(int, cov_vac.new_vaccinations)) OVER (PARTITION BY cov_dea.location 
    ORDER BY cov_dea.location, cov_dea.date) as PeopleVaccinated_Count
FROM CovidDeaths cov_dea
JOIN CovidVaccinations cov_vac
    ON cov_dea.[location] = cov_vac.[location]
    AND cov_dea.[date] = cov_vac.[date]
WHERE cov_dea.continent IS NOT NULL
AND cov_vac.new_vaccinations IS NOT NULL
ORDER BY 2,3

--Using CTE
WITH PopulationVsVaccinations (Continent, Location, Date, Population, New_Vaccinations, PeopleVaccinated_Count)
AS
(
SELECT cov_dea.continent, cov_dea.[location], cov_dea.[date], cov_dea.population,
    cov_vac.new_vaccinations, 
    SUM(CONVERT(int, cov_vac.new_vaccinations)) OVER (PARTITION BY cov_dea.location 
    ORDER BY cov_dea.location, cov_dea.date) as PeopleVaccinated_Count
FROM CovidDeaths cov_dea
JOIN CovidVaccinations cov_vac
    ON cov_dea.[location] = cov_vac.[location]
    AND cov_dea.[date] = cov_vac.[date]
WHERE cov_dea.continent IS NOT NULL
AND cov_vac.new_vaccinations IS NOT NULL
--ORDER BY 2,3
)
SELECT * , (1.0 * PeopleVaccinated_Count/Population) * 100 as Percentage_Vaccinated
FROM PopulationVsVaccinations


--TEMP Table Example

DROP TABLE IF EXISTS #PopulationVaccinatedPercentage
Create TABLE #PopulationVaccinatedPercentage 
(
    Continent NVARCHAR(255), 
    Location NVARCHAR(255), 
    Date datetime, 
    Population numeric, 
    New_Vaccinations numeric, 
    PeopleVaccinated_Count numeric
)
INSERT INTO #PopulationVaccinatedPercentage
SELECT cov_dea.continent, cov_dea.[location], cov_dea.[date], cov_dea.population,
    cov_vac.new_vaccinations, 
    SUM(CONVERT(int, cov_vac.new_vaccinations)) OVER (PARTITION BY cov_dea.location 
    ORDER BY cov_dea.location, cov_dea.date) as PeopleVaccinated_Count
FROM CovidDeaths cov_dea
JOIN CovidVaccinations cov_vac
    ON cov_dea.[location] = cov_vac.[location]
    AND cov_dea.[date] = cov_vac.[date]
WHERE cov_dea.continent IS NOT NULL
AND cov_vac.new_vaccinations IS NOT NULL
--ORDER BY 2,3

SELECT * , (1.0 * PeopleVaccinated_Count/Population) * 100 as Percentage_Vaccinated
FROM #PopulationVaccinatedPercentage

-- Creating VIEW examples - helps in data visualization

CREATE VIEW PopulationVaccinatedPercent AS
SELECT cov_dea.continent, cov_dea.[location], cov_dea.[date], cov_dea.population,
    cov_vac.new_vaccinations, 
    SUM(CONVERT(int, cov_vac.new_vaccinations)) OVER (PARTITION BY cov_dea.location 
    ORDER BY cov_dea.location, cov_dea.date) as PeopleVaccinated_Count
FROM CovidDeaths cov_dea
JOIN CovidVaccinations cov_vac
    ON cov_dea.[location] = cov_vac.[location]
    AND cov_dea.[date] = cov_vac.[date]
WHERE cov_dea.continent IS NOT NULL
AND cov_vac.new_vaccinations IS NOT NULL

SELECT * 
FROM PopulationVaccinatedPercent
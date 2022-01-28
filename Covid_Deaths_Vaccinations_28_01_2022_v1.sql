SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--Select data that we will use

SELECT 
  location, 
  date, 
  total_cases, 
  new_cases, 
  total_deaths, 
  population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Case Fatality Rate (CFR, Total Cases vs Total Deaths)

SELECT 
  location, 
  date, 
  total_cases, 
  total_deaths,
  (total_deaths/total_cases) * 100 AS CFR
FROM PortfolioProject..CovidDeaths
WHERE location = 'Germany'
AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Infection Rate (Total Cases vs Population)
-- Examine what percentage of the Popuation contracted COVID

SELECT 
  location, 
  date, 
  total_cases, 
  population, 
  (total_cases/population)*100 AS infection_rate
FROM PortfolioProject..CovidDeaths
WHERE location = 'Germany'
AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate Compared to Population
SELECT 
  location, 
  population, 
  MAX(total_cases) AS Highest_Infection_Count, 
  MAX((total_cases/population))*100 AS infection_rate
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Germany'
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY infection_rate DESC


-- Looking at Countries with highest total COVID deaths

SELECT 
  location, 
  MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Germany'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


-- BREAKDOWN BY CONTINENT 
-- Showing continent with highest total death count

SELECT 
  continent, 
  MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Germany'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC



-- GLOBAL NUMBERS 

--Total global new cases, new deaths and CFR per day

SELECT 
  date, 
  SUM(new_cases) AS global_new_cases, 
  SUM(CAST(new_deaths AS INT)) AS global_new_deaths,
  (SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100) AS global_cfr
  --, total_deaths,(total_deaths/total_cases) * 100 AS CFR
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Germany'
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY 1,2


-- Total global new cases, new deaths and CFR 

SELECT 
  --date, 
  SUM(new_cases) AS global_new_cases, 
  SUM(CAST(new_deaths AS INT)) AS global_new_deaths,
  (SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100) AS global_cfr
  --, total_deaths,(total_deaths/total_cases) * 100 AS CFR
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Germany'
WHERE continent IS NOT NULL
--GROUP BY date 
ORDER BY 1,2


--VACCINES
-- Looking at Total Population vs Vaccinations 
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE to find population of people vaccinated per country

WITH pop_vaxxed (continent, location, date, population, new_vaccinations, rolling_vax_count)
AS 
(
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT 
  *, 
  (rolling_vax_count / population) * 100 AS percent_vaxxed
FROM pop_vaxxed


-- Use TEMP TABLE to find population of people vaccinated per country

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255), 
date datetime,
Population numeric, 
new_vaccinations numeric,
rolling_vax_count numeric, 
)

INSERT INTO #PercentPeopleVaccinated
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
  ON dea.location = vac.location
  AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT 
  *, 
  ((rolling_vax_count / population) * 100) AS percent_vaxxed
FROM #PercentPeopleVaccinated


--Creating VIEW to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


SELECT * 
FROM PercentPopulationVaccinated
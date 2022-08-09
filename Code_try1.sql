--Project #1 SQL --

--Verifying Data--

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

--Changing varchar variables to numeric--

EXEC sp_help 'CovidDeaths';

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases DECIMAL

ALTER TABLE CovidDeaths
ALTER COLUMN population DECIMAL

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases DECIMAL

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths DECIMAL

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths DECIMAL

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations DECIMAL

--WORKING WITH TABLE COVID DEATHS--

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


--Looking at Total Cases vs Total Deaths--

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%Afghanistan'
ORDER BY 1,2

--You have a 4% chance of dying if you are from Afghanistan rn (line 896)--
--Shows likelihood of dying if you contract covid in your country--

--Total Cases vs Population--

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CovidPercentagePerCapita
FROM CovidDeaths
WHERE location like '%States'
ORDER BY 1,2

--Shows what percentage of population got covid--
--In 25/06/21 (line 521) 10% of the people who got tested got confirmed that had covid--

--¿What countries have the highest infection rate compared to population?--

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--We can say that 65% of the population in Faeroe Islands got covid--

--Showing countries with highest death count per population--

SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--Lets do this analysis for continent insted of location--

--Showing the continents with the highest death count per population--

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--Analysis for global numbers--

--Global covid cases each day --
SELECT date, SUM(new_cases) 
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


SELECT date
, SUM(new_cases) AS total_cases
, SUM(new_deaths) AS total_deaths
, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Around the globe we can see a death percentage of 1.1%--
SELECT
SUM(new_cases) AS total_cases
, SUM(new_deaths) AS total_deaths
, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--WORKING WITH TABLE COVID VACCINATIONS--

--Looking at total population vs total vaccinations--
--Same code but two different ways of doing it--
--Option 1: USING A CTE--
WITH PopvsVac (continent, location, date, population, new_vaccinations, AggregatePeopleVaccinated)
AS
(
SELECT dea.continent
,dea.location
,dea.date
,dea.population
,vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS AggregatePeopleVaccinated
--(AggregatePeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *
, (AggregatePeopleVaccinated / population)*100
FROM PopvsVac

--With this code we can see how many people are vaccinated nowadays in each country--
--For example in Albania, nowadays almost 50% of the population is vaccinated--

--Option 2: USING A TEMP TABLE--
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
continent VARCHAR(255)
,location VARCHAR(255)
,date DATETIME
,population NUMERIC
,new_vaccination NUMERIC
,AggregatePeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent
,dea.location
,dea.date
,dea.population
,vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS AggregatePeopleVaccinated
--(AggregatePeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
, (AggregatePeopleVaccinated / population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations--
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent
,dea.location
,dea.date
,dea.population
,vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS AggregatePeopleVaccinated
--(AggregatePeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
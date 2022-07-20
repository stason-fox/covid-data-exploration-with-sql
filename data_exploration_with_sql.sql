/*
Covid 19 Data Exploration using SQL
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--Select data being used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Total cases vs total deaths
--Shows chances of dying if Covid is contracted in United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2;

--Total cases vs population
--Shows percentage of population infected with Covid
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

--Countries with highest death count per population
SELECT location, MAX(cast (total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Continents with highest death count per population
SELECT location, MAX(cast (total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location NOT LIKE 'World'
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Total global cases, deaths, and death percentage
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, SUM(cast(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL;

--Total global cases, deaths, and death percentage by date
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, SUM(cast(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

--Total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
INNER JOIN PortfolioProject.dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Percentage of population that received Covid vaccine (using CTE to perform calculation on PARTITION BY)
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
INNER JOIN PortfolioProject.dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentPopVaccinated
FROM PopVsVac;

--Using Temp Table to perform calculation on PARTITION BY
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
INNER JOIN PortfolioProject.dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentPopVaccinated
FROM #PercentPopulationVaccinated;

--Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
INNER JOIN PortfolioProject.dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
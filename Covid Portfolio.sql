Select *
FROM [Portfolio Project]..CovidDeaths
order by 3,4

-- so far what i have done is tuned up the data from Excel (split the table in 2 groups, deaths and vaccinations),
-- and data was then imported from excel workbook into a SQL Server, creating a new database
-- now we are querying data to manipualte it. 

-- selecting the data that we're going to be using 
Select location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths = shows the likelihood of dying in your country if you get covid 
-- converted data type on Total Deaths and Total cases to use divide operator
-- converted data type as . Some of the data in "Numeric" data type is actually float, thats why we need to convert it
-- (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100, NULLIF(CONVERT(float, total_cases), 0) is used to avoid division by zero errors
-- The NULLIF function takes two arguments and returns a null value if the two arguments are equal, otherwise it returns the first argument. In this case, NULLIF(CONVERT(float, total_cases), 0) returns a null value if total_cases is zero, and CONVERT(float, total_cases) otherwise.
Select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like '%states%' OR location like '%colombia%'
AND continent is not null
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of the population got covid
Select location, date, total_cases, population, (NULLIF(CONVERT(float, total_cases), 0) /CONVERT(float, population)) * 100 AS PercentageOfPoPSick
FROM [Portfolio Project]..CovidDeaths
Where location like '%states%'
order by 1,2

Select location, date, total_cases, population, (NULLIF(CONVERT(float, total_cases), 0) /CONVERT(float, population)) * 100 AS PercentageOfPoPSick
FROM [Portfolio Project]..CovidDeaths
Where location like '%mexico%'
order by 1,2

Select location, date, total_cases, population, (NULLIF(CONVERT(float, total_cases), 0) /CONVERT(float, population)) * 100 AS PercentageOfPoPSick
FROM [Portfolio Project]..CovidDeaths
Where location like '%canada%'
order by 1,2

--Looking at countries with highest infection rates compared to populatiaon. 
Select location,population, MAX(total_cases) as HightestInfectionCount, MAX(NULLIF(CONVERT(float, total_cases), 0) /CONVERT(float, population)) * 100 AS PercentPopulationInfection
FROM [Portfolio Project]..CovidDeaths
GROUP by location, population
Order by PercentPopulationInfection DESC

--Showing the countries with Highest Death Count Per Population
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP by location
Order by TotalDeathCount DESC

--Breaking things down by continent
SELECT location,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP by location
Order by TotalDeathCount DESC

-- showing the continents with the highest death count
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP by continent
Order by TotalDeathCount DESC



--Global Numbers
Select  date,SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totalDeaths, (SUM(cast(new_deaths as int))/SUM(NULLIF(CONVERT(float, new_cases), 0))*100) as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
Where continent is not null
GROUP BY date
order by DeathPercentage DESC

Select  SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totalDeaths, (SUM(cast(new_deaths as int))/SUM(NULLIF(CONVERT(float, new_cases), 0))*100) as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
Where continent is not null
--GROUP BY date
order by 1,2

--looking at total population vs vaccinations
--what amount of people in the world have been vaccinated
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations ,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date)
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

--This is the interpretation of the code written, as this is complicated and I am learning SQL
--This SQL query is selecting data from two tables, CovidDeaths and CovidVaccines, and joining them on the columns location and date. 
--The SUM function is used to calculate the total number of new vaccinations for each location. 
--The OVER clause is used to specify the window over which the SUM function should be applied. In this case, the window is defined by the Partition by clause, which partitions the data by location, and the order by clause, which orders the data by location and date. 
--The WHERE clause filters the results to only include records where the continent column is not null. Finally, the results are ordered by the second and third columns of the select statement, which are location and date, respectively.

--Next query will do a  running total of the population vaccinated.  We will need to create a temporary table USING CTE
-- using CTE
-- first line declares the CTE and specifies the columns we will input 

with PopsVac(continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations ,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)
select *,(RollingPeopleVaccinated/population)*100
FROM PopsVac

--doing the same but with a temp table
--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)
insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations ,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

select *,(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--CREATING VIEW TO STORE DATE FOR LATER VISUALIZATIONS

create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations ,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

select *
FROM PercentPopulationVaccinated


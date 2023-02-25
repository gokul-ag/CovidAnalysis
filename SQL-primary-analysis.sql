select * from PortfolioProject..covidDeaths$
order by 3,4;

select distinct continent, location from
PortfolioProject..covidDeaths$; -- Continents, world, etc are also added as observation which is not required

--select * from PortfolioProject..covidDeaths$
--order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..covidDeaths$
where continent is not null
order by 1,2;

-- Studying total cases vs total deaths (likelihood of death if a person contracts Covid in India)

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.covidDeaths$
where location = 'India' and continent is not null
order by 1,2;


-- Percentage of population affected by Covid

select location, date, population, total_cases, (total_cases/population)*100 as InfectedPopulationPercentage
from PortfolioProject.dbo.covidDeaths$
-- where location = 'India'
where continent is not null
order by 1,2;


-- Countries with highest infection rates compared to population

select location, population, MAX(total_cases) as HighestCase, MAX(total_cases/population)*100 as MaxInfectedPopulationPercentage
from PortfolioProject.dbo.covidDeaths$
-- where date between '2020-02-24' and '2021-04-30'
-- where location = 'India'
where continent is not null
group by location, population
order by MaxInfectedPopulationPercentage desc;


-- Countries with Highest Death Count per population

select location, MAX(CAST(total_deaths as INT)) as HighestDeathCase
from PortfolioProject.dbo.covidDeaths$
-- where date between '2020-02-24' and '2021-04-30'
-- where location = 'India'
where continent is not null
group by location
order by HighestDeathCase desc;

-- Death Count by continent

select continent, MAX(CAST(total_deaths as INT)) as HighestDeathCase
from PortfolioProject.dbo.covidDeaths$
-- where date between '2020-02-24' and '2021-04-30'
-- where location = 'India'
where continent is not null
group by continent
order by HighestDeathCase desc;

--select location, MAX(cast(total_deaths as int)) as HighestDeathCase
--from PortfolioProject.dbo.covidDeaths$
---- where date between '2020-02-24' and '2021-04-30'
---- where location = 'India'
--where continent is null
--group by location
--order by HighestDeathCase desc;

-- Analysis across the globe 
-- 1. Cases, deaths and percentage by day

select date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as INT)) as TotalDeaths,
       (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as DeathPercentage
from PortfolioProject..covidDeaths$
where continent is not null
group by date
order by date;

-- 2. Overall figures

select SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as INT)) as TotalDeaths,
       (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as DeathPercentage
from PortfolioProject..covidDeaths$
where continent is not null;

-- Merging datasets
-- 1. Studying Total Population vs Vaccination

select cd.continent, cd.location, cd.date, population, new_vaccinations
from PortfolioProject..covidDeaths$ as cd
join PortfolioProject..covidVaccination$ as cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null
order by 2,3;

-- 2. Rolling total (over clause)

select cd.continent, cd.location, cd.date, population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) as RollingTotal
from PortfolioProject..covidDeaths$ as cd
join PortfolioProject..covidVaccination$ as cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null
order by 2,3;

-- 3. Using CTE

with PopVsVac (continent, location, date, population, new_vaccinations, RollingTotal)
as
(select cd.continent, cd.location, cd.date, population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) as RollingTotal
from PortfolioProject..covidDeaths$ as cd
join PortfolioProject..covidVaccination$ as cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null
)
select *, (RollingTotal/Population)*100 as VaccPercentage from PopVsVac
order by 2,3;

-- alternative (Using temp tables)

drop table if exists #PopVsVac
create table #PopVsVac (continent nvarchar(255), location nvarchar(255), date datetime, 
poulation numeric, new_vaccinations numeric, RollingTotal numeric)
insert into #PopVsVac
select cd.continent, cd.location, cd.date, population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) as RollingTotal
from PortfolioProject..covidDeaths$ as cd
join PortfolioProject..covidVaccination$ as cv
on cd.location = cv.location and cd.date = cv.date;

select * from #PopVsVac
where continent is not null
order by 2,3;

-- Create View
GO
create view RollTotal as
select cd.continent, cd.location, cd.date, population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) as RollingTotal
from PortfolioProject..covidDeaths$ as cd
join PortfolioProject..covidVaccination$ as cv
on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null;
GO

select * from RollTotal;
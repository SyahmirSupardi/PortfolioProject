select *
from PortfolioProject..[Covid Deaths]


select *
from PortfolioProject..[Covid Vaccinations]
where continent is not null and continent != ' '
order by 3,4

-- select Data that we are going to be using

select Location, Date, total_cases, new_cases, total_deaths, population
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Show likelihood of dying if you contract covid in your country
select Location, Date, total_cases, total_deaths, (convert(float,total_deaths)/nullif(convert(float,total_cases),0))*100 as DeathPercentage
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
order by 1,2

select Location, date, total_cases, total_deaths, (convert(float,total_deaths)/nullif(convert(float,total_cases),0))*100 as DeathPercentage
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
where location like '%Malaysia%'
order by 1,2

-- Looking at Total Cases vs Population

select Location, date, total_cases, population, (convert(float,total_cases)/nullif(convert(float,population),0))*100 as PopulationPercentageInfection
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
where location like '%Malaysia%'
order by 1,2

-- Looking at Country with Highest Infection Rate compared to Population

select Location, population, Max(total_cases) as HighestInfectionCount, Max(convert(float,total_cases)/nullif(convert(float,population),0))*100 as PopulationPercentageInfection
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
--where location like '%Malaysia%'
Group by location,population
order by PopulationPercentageInfection desc

-- Showing Countries with Highest Death Count per Population

select Location, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
--where location like '%Malaysia%'
Group by Location
order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
--where location like '%Malaysia%'
Group by continent
order by TotalDeathCount desc

-- Showing continents with the highest death count per population

select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[Covid Deaths]
where continent is not null and continent != ' '
--where location like '%Malaysia%'
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT 
    SUM(CAST(new_cases AS BIGINT)) AS TotalNewCases, 
    SUM(CAST(new_deaths AS BIGINT)) AS TotalNewDeaths, 
    CASE 
        WHEN SUM(CAST(new_cases AS BIGINT)) = 0 THEN 0
        ELSE (SUM(CAST(new_deaths AS BIGINT)) * 100.0) / NULLIF(SUM(CAST(new_cases AS BIGINT)), 0)
    END AS DeathPercentage
FROM PortfolioProject..[Covid Deaths]
WHERE continent IS NOT NULL 
  AND continent != ' ' 
  AND new_cases != '0'  -- Filtering out rows where new_cases is 0
ORDER BY 1, 2;



-- Looking at Total Population vs Vaccinations

select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vax.new_vaccinations,
	sum(convert(bigint, vax.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated

from PortfolioProject..[Covid Deaths] as dea
join PortfolioProject..[Covid Vaccinations] as vax
	on dea.location = vax.location
	and dea.date = vax.date

where dea.continent is not null
	and dea.continent != ' '
order by 2,3


-- USE CTE

with PopvsVax (continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as 
(
select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vax.new_vaccinations,
	sum(convert(bigint, vax.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated

from PortfolioProject..[Covid Deaths] as dea
join PortfolioProject..[Covid Vaccinations] as vax
	on dea.location = vax.location
	and dea.date = vax.date

where dea.continent is not null
	and dea.continent != ' '
--order by 2,3
)

select *,(RollingPeopleVaccinated/Population)*100
from PopvsVax



-- TEMP TABLE

drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
);

insert into #PercentPopulationVaccinated
select 
	dea.continent, 
	dea.location, 
	dea.date, 
	try_cast(dea.population as numeric), 
	try_cast(vax.new_vaccinations as numeric),
	sum(convert(bigint, vax.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated

from PortfolioProject..[Covid Deaths] as dea
join PortfolioProject..[Covid Vaccinations] as vax
	on dea.location = vax.location
	and dea.date = vax.date

where dea.continent is not null
	and dea.continent != ' '
--order by 2,3


select *,(RollingPeopleVaccinated/Population)*100
from PopvsVax



-- Creating view to store data for later visualization

create view PercentPopulationVaccinated as

select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vax.new_vaccinations,
	sum(convert(bigint, vax.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated

from PortfolioProject..[Covid Deaths] as dea
join PortfolioProject..[Covid Vaccinations] as vax
	on dea.location = vax.location
	and dea.date = vax.date

where dea.continent is not null
	and dea.continent != ' '
--order by 2,3


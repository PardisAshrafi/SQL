select * from CovidProject..CovidDeaths

select * from CovidProject..CovidVaccinations
order by 3,4



select location,date,total_cases,new_cases,total_deaths,population
from CovidProject..CovidDeaths
order by 1,2


-- looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country 

select location,date,total_cases,total_deaths, (total_deaths/NULLIF (total_cases,0)) * 100 as DeathPercentage
from CovidProject..CovidDeaths
where location like '%states'
order by 1,2



ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT;




-- looking at Total Cases vs Population
-- shows what percentage of population got covid

select location,date,total_cases,population, (total_cases/population) * 100 as PercentPopulationInfected
from CovidProject..CovidDeaths
where location like '%states'
order by 1,2




-- looking at Countries with Highest Infection Rate compared to Population

select location, MAX(CAST(population as bigint)) as population, max(cast(total_cases as bigint)) as HighestInfectionCount, max((cast(total_cases as float) *100) /NULLIF(cast(population as float),0))  as PercentPopulationInfected
from CovidProject..CovidDeaths
--where location like '%states' 
WHERE cast(population as float) > 0
group by location, population
order by PercentPopulationInfected desc


-- showing Countries with Highest Death Count per Population

select location, MAX(total_deaths) as TotalDeathCount
from CovidProject..CovidDeaths 
group by location
order by TotalDeathCount desc




-- let's break things down by continent

-- showing contintents with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths 
where continent is not null
group by continent
order by TotalDeathCount desc



-- Global Numbers

select location,date,total_cases,total_deaths, (total_deaths/NULLIF (total_cases,0)) * 100 as DeathPercentage
from CovidProject..CovidDeaths
--where location like '%states'
where continent IS NOT NULL 
order by 1,2



-- looking at total population vs vaccinations

select * 
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date



select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
order by 2,3





--use CTE 

with PopvsVac (continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,(RollingPeopleVaccinated /NULLIF(convert(bigint,population),0))*100 AS PercentVaccinated 
from PopvsVac





if OBJECT_ID('tempdb..#PercentPopulationVaccinated') is not null
drop table #PercentPopulationVaccinated













-- Temp Table 






Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    CASE 
        WHEN ISNUMERIC(dea.population) = 1 THEN CONVERT(NUMERIC, dea.population)
        ELSE NULL 
    END as Population,
    CASE 
        WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CONVERT(NUMERIC, vac.new_vaccinations)
        ELSE NULL 
    END as New_vaccinations,
    SUM(
        CASE 
            WHEN ISNUMERIC(vac.new_vaccinations) = 1 THEN CONVERT(BIGINT, vac.new_vaccinations)
            ELSE 0 
        END
    ) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) as RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


SELECT * FROM #PercentPopulationVaccinated
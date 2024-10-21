--1

select * 
from projectPortfolio..CovidDeaths 
where continent is not null
order by 3,4

--select * 
--from projectPortfolio..CovidVaccinations 
--order by 3,4


--2
--Select the data that we are going to be using. 
select location, date, total_cases, new_cases, total_deaths, population
from projectPortfolio..CovidDeaths
where total_cases is not null
and new_cases is not null
and total_deaths is not null
order by 1,2


--3
--Looking at Total Cases vs Total Deaths by %
--Shows the likelyshood of dying from covid 
select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/NULLIF(CONVERT(float,total_cases),0)) *100 as DeathPercentage
from projectPortfolio..CovidDeaths
where total_cases is not null
and total_cases is not null
order by 1,2


--4
--Looking at Total Cases vs Total Deaths by % in the States
--Shows the likelyshood of dying from covid 
select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/NULLIF(CONVERT(float,total_cases),0)) *100 as DeathPercentage
from projectPortfolio..CovidDeaths
where location like '%states%'
and total_cases is not null
and total_cases is not null
order by 1,2


--5
--Looking at the Total Cases vs Population in the States
--Shows what percentage got covid
select location, date, population, total_cases, (CONVERT(float, total_cases)/NULLIF(CONVERT(float,population),0)) *100 as InfectionPercentage
from projectPortfolio..CovidDeaths
where location like '%states%'
and total_cases is not null
order by 1,2


--6(used in TABLEAU)
--Looking at Countries with the highest infection rate compared to population
select location, population, MAX(total_cases) as highestInfectionCount, MAX((CONVERT(float, total_cases)/NULLIF(CONVERT(float,population),0))) *100 as InfectionPercentage
from projectPortfolio..CovidDeaths
--where location like '%states%'
--and total_cases is not null
group by location, population
order by InfectionPercentage desc


--6b(Used In TABLEAU)
select location, population, date, MAX(total_cases) as highestInfectionCount, MAX((CONVERT(float, total_cases)/NULLIF(CONVERT(float,population),0))) *100 as InfectionPercentage
from projectPortfolio..CovidDeaths
--where location like '%states%'
--and total_cases is not null
group by location, population, date
order by InfectionPercentage desc

--7
--Breaking things down by conitnent
select location, MAX(cast(total_deaths as int)) as totalDeathCount
from projectPortfolio..CovidDeaths
where continent is null
and location != 'High income'
and location != 'Upper middle income'
--and total_cases is not null
group by location
order by totalDeathCount desc


--8
--Showing the countries with the highestdeath count per population
select location, MAX(cast(total_deaths as int)) as totalDeathCount
from projectPortfolio..CovidDeaths
where continent is not null
--and total_cases is not null
group by location
order by totalDeathCount desc


--9
--Showing the continents with the highest death count per population
select continent, MAX(cast(total_deaths as int)) as totalDeathCount
from projectPortfolio..CovidDeaths
where continent is not null
--and total_cases is not null
group by continent
order by totalDeathCount desc


--10
--Calculate global numbers
select date, SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, Sum(new_deaths)/Sum(new_cases)*100 as deathPercentage
from projectPortfolio..CovidDeaths
where continent is not null
and new_cases is not null
and new_deaths is not null 
group by date
order by 1,2


--11
--Calculate global numbers grouped by date
select date, SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, Sum(new_deaths)/Sum(new_cases) as deathPercentage
from projectPortfolio..CovidDeaths
where continent is not null
group by date
order by 1,2


--12(Used int TABLEAU)
--Calculate global numbers without date
select SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, Sum(new_deaths)/Sum(new_cases)*100 as deathPercentage
from projectPortfolio..CovidDeaths
where continent is not null
order by 1,2


--13
--Looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from projectPortfolio..CovidDeaths dea
join projectPortfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--14
--Looking at total population vs vaccinations by location orderd by both location and date
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as BIGINT)) OVER (Partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from projectPortfolio..CovidDeaths dea
join projectPortfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--15
--USE CTE to use column that was just created: rollingPeopleVaccinated
with popvsvac(continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as BIGINT)) OVER (Partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from projectPortfolio..CovidDeaths dea
join projectPortfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,  (rollingPeopleVaccinated/population)*100
from popvsvac


--16
--temp table
--added 'drop table if exists' incase alterations were made
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255),
date datetime, 
population numeric, 
new_vaccinations numeric, 
rollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as BIGINT)) OVER (Partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from projectPortfolio..CovidDeaths dea
join projectPortfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *,  (rollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated



--17
--creating views to store for later vizualizations
create view PercentPoplationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as BIGINT)) OVER (Partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from projectPortfolio..CovidDeaths dea
join projectPortfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * 
from PercentPoplationVaccinated


--18(USed in TABLEAU)
--Taking out 'World', "European Union', and "International'
Select location, SUM(cast(new_deaths as bigint)) as totalDeathCount
from projectPortfolio..CovidDeaths
where continent is null 
and location not in ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 
'Upper middle income', 'High income')
group by location
order by totalDeathCount desc


--19
create view HighestDeathCount as 
select continent, MAX(cast(total_deaths as int)) as totalDeathCount
from projectPortfolio..CovidDeaths
where continent is not null
--and total_cases is not null
group by continent
--order by totalDeathCount desc

select * 
from HighestDeathCount


--20
create view HighestInfectionRate as 
select location, population, MAX(total_cases) as highestInfectionCount, MAX((CONVERT(float, total_cases)/NULLIF(CONVERT(float,population),0))) *100 as InfectionPercentage
from projectPortfolio..CovidDeaths
--where location like '%states%'
--and total_cases is not null
group by location, population
--order by InfectionPercentage desc

select * 
from HighestInfectionRate

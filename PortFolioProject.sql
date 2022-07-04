SET ANSI_WARNINGS OFF
GO
--New tables
select * from PortfolioProject..Vaccinations
select * from PortfolioProject..Deaths

-- Data for total and new cases for each country on each date
select location,date,total_cases,total_deaths,new_cases,population from PortfolioProject..Deaths where continent is not null order by 1,2;

-- total cases vs total deaths. death likelihood

select Location,date,Total_cases,Total_deaths,(total_deaths/total_cases * 100) as Death_Percentage,new_cases,New_deaths,
(new_deaths/(case when new_cases = 0 then 1 else new_cases end) * 100) as NewDeath_Precent, (case when new_cases = 0 then 1 else new_cases end) as new_z_cases
from PortfolioProject..Deaths where location = 'india' and continent is not null order by 1,2;

-- total cases vs population

select Location,date,Total_cases,population, (total_cases/population * 100 ) as cases_perPopulation_percent
from PortfolioProject..Deaths where location = 'india' and continent is not null  order by 1,2;

-- countries with high infection rate
select location,population,max(total_cases) as HighestInfectionCount, max((total_cases/population) * 100 ) as PercentPopulationInfected 
from PortfolioProject..Deaths --where location = 'india' and continent is not null 
group by location,population order by PercentPopulationInfected desc;

select location,max(population) from PortfolioProject..Deaths group by location order by location

--countries with high deathrate

select location,continent,max(cast(total_deaths as int)) as TotaldeathCount, max((total_deaths/population) * 100 ) as PercentPopulationDead 
from PortfolioProject..Deaths where continent is null --and location = 'india'
group by location,continent order by PercentPopulationDead desc;

-- data by date
select date, SUM(new_cases) as total_cases, sum(CAST(new_deaths as int)) as total_deaths,
sum(CAST(new_deaths as int))/SUM(case when new_cases = 0 then 1 else new_cases end) * 100 as death_percent from PortfolioProject..Deaths 
where continent is not null group by date order by 1,2;

-- Worldwide data
select  SUM(new_cases) as total_cases, sum(CAST(new_deaths as int)) as total_deaths,
sum(CAST(new_deaths as int))/SUM(case when new_cases = 0 then 1 else new_cases end) * 100 as death_percent from PortfolioProject..Deaths 
where continent is not null order by 1,2;

-- Countries with Total cases on 29th june where new cases greater than 10000
with s as (
select  location, date, SUM(new_cases) as total_cases, sum(CAST(new_deaths as int)) as total_deaths,
sum(CAST(new_deaths as int))/SUM(case when new_cases = 0 then 1 else new_cases end) * 100 as death_percent from PortfolioProject..Deaths 
where continent is not null and date in ('2022-06-29') group by location,date)

select location,date, total_cases, total_deaths, death_percent from s where total_cases > 10000 order by total_cases desc;

--Vaccinations Data

Select vac.continent,vac.location, vac.date,dea.population,vac.new_vaccinations, sum(CONVERT(bigint,vac.new_vaccinations)) over (partition by vac.location) 
as dialyTotalCount from PortfolioProject..Vaccinations vac join PortfolioProject..Deaths dea on vac.location = dea.location and vac.date = dea.date
where vac.continent is not null order by 2,3

with S(Continent,Location,Date,Population,New_Vaccinations,DialyVaccineCount) as
(
Select dea.continent,dea.location, dea.date,dea.population,vac.new_vaccinations, 
sum(CAST(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location,dea.date) as DialyVaccineCount
from PortfolioProject..Deaths dea join PortfolioProject..Vaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null)
select *, DialyVaccineCount/population * 100 as VaccinationPercent from S order by 2,3;

--- temp Table creation using #
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
(Continent NVARCHAR(255),
Location NVARCHAR(255),
Date datetime,
Population Numeric, New_Vaccinations Numeric,DialyVaccineCount Numeric )

insert into #PercentPopulationVaccinated 
Select dea.continent,dea.location, dea.date,dea.population,vac.new_vaccinations, 
sum(CAST(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location,dea.date) as DialyVaccineCount
from PortfolioProject..Deaths dea join PortfolioProject..Vaccinations vac on dea.location = vac.location and dea.date = vac.date
--where dea.continent is not null

select *, DialyVaccineCount/population * 100 as VaccinationPercent from #PercentPopulationVaccinated order by 2,3;

-- Create view for later Visualizations

CREATE VIEW PercentPopulationVaccinated as 
Select dea.continent,dea.location, dea.date,dea.population,vac.new_vaccinations, 
sum(CAST(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location,dea.date) as DialyVaccineCount
from PortfolioProject..Deaths dea join PortfolioProject..Vaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null;

select * from PercentPopulationVaccinated;


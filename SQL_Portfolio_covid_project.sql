-- Data sourse: https://ourworldindata.org/covid-deaths 

--Let's just look at our prepared data
select *
from Covid_deaths
where continent is not null
order by 3,4


-- Selecting data for further work - just look at data 
select continent, location, date, total_cases, new_cases, total_deaths, population
from Covid_deaths
where continent is not null
order by location, date


-- Let's look at % of deaths bc of Covid in Russia 
select location, date, convert(decimal(15,0), total_cases) as total_cases, 
convert(decimal(15,0), total_deaths) as total_deaths, convert(decimal(15,2), convert(decimal(15,0), total_deaths) / convert(decimal(15,0), total_cases) *100) as '% of deaths'
from Covid_deaths
where location = 'Russia' and continent is not null
order by date desc
-- as we can see, if you live in Russia you have a 1.74% chance of dying from Covid if you become infected (as of October 4, 2023) - low % is a good news :)


-- Let's look at % of population of Russia that had Covid 
select location, date, convert(decimal(15,0), total_cases) as total_cases, 
convert(decimal(15,0), population) as population, convert(decimal(15,2), total_cases / population *100) as '% of infected ppl'
from Covid_deaths
where location = 'Russia' and continent is not null
order by date desc
-- almost 15.9% of Russians had covid 
-- also we can see that total number of infected people was 23+ millions


-- if we want to know about other countries too 
select location, date, convert(decimal(15,0), total_cases) as total_cases, 
convert(decimal(15,0), population) as population, convert(decimal(15,2), total_cases / population *100) as '% of infected ppl'
from Covid_deaths
where continent is not null and total_cases is not null
order by 1,2 desc


-- if we want to know about highest infected rate / population
select location, max(cast(total_cases as int)) as highest_infection_count, 
convert(decimal(15,0), population) as population, max(convert(decimal(15,2), total_cases / population *100)) as '% of infected ppl'
from Covid_deaths
where continent is not null
group by location, population
order by '% of infected ppl' desc
-- as we can see, Cyprus has the highest number of infected people - 73.76%


-- if we want to know about highest % of deaths / population
select location, max(cast(total_deaths as int)) as highest_deaths_count, 
convert(decimal(15,0), population) as population, max(convert(decimal(15,2), total_deaths / population *100)) as '% of deaths'
from Covid_deaths
where continent is not null
group by location, population
order by '% of deaths' desc
-- as we can see the highest % of deaths because of Covid in Peru - 0.65% 


--Let's look at countries where number of deaths is the highest
select location, max(cast(total_deaths as int)) as highest_deaths_count
from Covid_deaths
where continent is not null
group by location
order by highest_deaths_count desc
--the highest number of deaths we see in US but Russia also in top5 countries


--Also let's take a look at this numbers by continent
select continent, max(cast(total_deaths as int)) as highest_deaths_count
from Covid_deaths
where continent is not null
group by continent
order by highest_deaths_count desc
--Now we see that highest numbers of deaths are in North and South America
-- I think it's surprise that Asia is not on the first place - because first Covid cases were there 


--Let's take a look at GLOBAL NUMBERS
-- for all time
select sum(new_cases) as sum_of_new_cases,
       sum(new_deaths) as sum_of_new_deaths,
	   convert(decimal(15,2),nullif(sum(new_deaths),0)/nullif(sum(new_cases),0) *100) as death_percentage
from Covid_deaths
where continent is not null
order by 1,2
-- omg 6 millions deaths that's A LOT - but I think it's good that death percent is lower than 1%

--per day
select date, sum(new_cases) as sum_of_new_cases,
             sum(new_deaths) as sum_of_new_deaths,
			 convert(decimal(15,2),nullif(sum(new_deaths),0)/nullif(sum(new_cases),0) *100) as death_percentage
from Covid_deaths
where continent is not null
group by date
order by 1


--Join our tables & looking at total population / Vaccination
select death.continent, death.location, death.date, population, vac.new_vaccinations,
       sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location order by death.location, death.date) as count_new_vac_ppl
-- let's use 'new_vaccinations' just because we want to know how many new vac ppl have per day
from Covid_deaths as death
join Covid_vac as vac
     on death.location = vac.location and death.date = vac.date
where death.continent is not null
order by 2,3


--we can use 2 types of instruments for data manipulation
-- use CTE
with total_pop_vs_vac (continent, location, date, population, new_vaccinations, count_new_vac_ppl)
as (
select death.continent, death.location, death.date, population, vac.new_vaccinations,
       sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location order by death.location, death.date) as count_new_vac_ppl
-- let's use 'new_vaccinations' just because we want to know how many new vac ppl have per day
from Covid_deaths as death
join Covid_vac as vac
     on death.location = vac.location and death.date = vac.date
where death.continent is not null
)
select *, convert(decimal(15,2),(count_new_vac_ppl / population) *100) as '%_of_vac_ppl'
from total_pop_vs_vac
where location = 'Russia'
order by '%_of_vac_ppl' desc
-- as we can see for '12/04/2022' 105% of russians have been vaccinated - 
--that's because in Russia you should do your vac every 6 months - i think because of that we have 105%


--use temp_tables
drop table if exists #percent_pf_vac_ppl
create table #percent_pf_vac_ppl (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
count_new_vac_ppl numeric )

insert into #percent_pf_vac_ppl
select death.continent, death.location, death.date, population, vac.new_vaccinations,
       sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location order by death.location, death.date) as count_new_vac_ppl
-- let's use 'new_vaccinations' just because we want to know how many new vac ppl have per day
from Covid_deaths as death
join Covid_vac as vac
     on death.location = vac.location and death.date = vac.date
where death.continent is not null

select *, convert(decimal(15,2),(count_new_vac_ppl / population) *100) as '%_of_vac_ppl'
from #percent_pf_vac_ppl
where location = 'Russia'
order by '%_of_vac_ppl' desc
-- we have same resaults by using temp tables


-- creating view to store data for later visualisation 
create view Percent_of_vac_ppl as 
select death.continent, death.location, death.date, population, vac.new_vaccinations,
       sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location order by death.location, death.date) as count_new_vac_ppl
-- let's use 'new_vaccinations' just because we want to know how many new vac ppl have per day
from Covid_deaths as death
join Covid_vac as vac
     on death.location = vac.location and death.date = vac.date
where death.continent is not null

select *
from Percent_of_vac_ppl

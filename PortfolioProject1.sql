/* This project aims to explore Covid-19 data and summarise the key points in Singapore's fight against the Covid-19 pandemic */
--Select *
--From PortfolioProject..CovidDeaths
--order by location, date

--Select *
--From PortfolioProject..CovidVaccinations
--order by location, date

--Select location, date, total_cases, new_cases, total_deaths, population
--From PortfolioProject..CovidDeaths
--order by location, date 

/*
First comparison: Total Cases vs Total Deaths for Singapore
This query will compute and show the Case Fatality Rate of Covid-19 in Singapore.
The Case Fatality Rate refers to the proportion of deaths caused by Covid-19 compared to the total number of people infected with Covid-19, to evaluate the handling of Covid-19 cases and the likelihood of dying if you are infected with Covid-19 in Singapore.
*/
Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 As 'Case Fatality Rate'
From PortfolioProject..CovidDeaths
Where location = 'Singapore'
Order by location, date 

/* 
Second comparison: Total Percentage of the Population in Singapore infected
This query was formed to identify the % of the population in Singapore infected with Covid-19.
*/
Select location, date, total_cases, new_cases, population, (total_cases/population)*100 As 'Infected %'
From PortfolioProject..CovidDeaths
Where location = 'Singapore'
Order by location, date

/* Third comparison: Ranking Countries in accordance to % of Population infected with Covid-19
This query identifies all countries' infection rates and helps to compare how Singapore ranks against other countries in preventing the spread of Covid-19

Based on the findings shown, Singapore is ranked 77th place out of 192 countries in preventing the spread of Covid-19
*/
Select location, Max(total_cases) As 'Infection Count', Max((total_cases/population)*100) As 'Percentage of Pop. Infected'
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Having Max(total_cases) is not null --There are countries in the database without any values because they did not report any Covid-19 infection counts during the period. Hence, I used the Having clause to exclude them from the query.
Order by [Percentage of Pop. Infected], [Infection Count]

/*
Fourth Comparison: Ranking Countries with Highest Mortality Rate (Death Count per Population Size) 
This query computes each country's total death count and their mortality rate, which refers to the frequency of death in a defined population during a specified interval.
Thereafter, I rank them according to their mortality rate for relativity in comparison against Singapore's Mortality Rate.
*/
Select location, Max(cast(total_deaths as int)) As 'Death Count', Max(((cast(total_deaths as int)/population)*100)) As 'Mortality Rate'
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by [Mortality Rate] Desc, [Death Count] Desc

/*Fifth Comparison: Continents with the highest death count and mortality rates 
This query tabulates the death count and Mortality Rate in each continent or region to understand how the other continents are performing as compared to Singapore (in the Southeast Asian region)
*/
Select location, Max(cast(total_deaths as int)) As 'Total Death Count', Max(((cast(total_deaths as int))/population)*100) As 'Mortality Rate'
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by [Mortality Rate] Desc, [Total Death Count] Desc

/*Sixth Comparison: Global Covid-19 Death Count, Mortality Rate, and Case Fatality Rate
The following query written are the global metrics that are computed by adding all new cases, new deaths accumulated across all locations and calculating the metrics I wanted.
*/
Select date, 
IsNull(Sum(new_cases),0) As 'Global Case Count', 
IsNull(Sum(cast(new_deaths as int)),0) As 'Global Death Count', 
IsNull(Sum(((cast(new_deaths as int))/population)*100),0) As 'Global Mortality Rate', 
IsNull((Sum((cast(new_deaths as int))/total_cases)*100),0) As 'Global Case Fatality Rate'
From PortfolioProject..CovidDeaths
Where continent is not null -- This is to exclude continents listed as locations in the dataset and avoid double counting of cases
Group by date
Order by date

/*Seventh Comparison: Singapore's Death Count, Mortality Rate, and Case Fatality (Death-to-Case) Rate 
This query creates a summary of the virus' deadliness in Singapore.
*/
Select date, location, 
total_cases As 'Total Cases', 
IsNull(total_deaths, 0) As 'Total Death Count', -- Because I had the intention to put all the comparisons here into Tableau Public to create a dashboard or story, I inserted the IsNull Function here and changed all the NULL values to 0.
IsNull(((cast(total_deaths as int))/population),0)*100 As 'Mortality Rate', 
IsNull(((cast(total_deaths as int)/total_cases)*100),0) As 'Case Fatality Rate'
From PortfolioProject..CovidDeaths
Where continent is not null and location = 'Singapore'
Order by date -- To ensure that the data shown are displayed in a time-series manner.

/*After computing the above seven metrics and comparisons to understand the deadliness of the virus across the world and in Singapore, 
I take vaccination data from the table 'CovidVaccinations' to calculate vaccination rates for Singapore and the Case Fatality Rate to see if there is any influence of the vaccine on Covid-19 deaths.
*/
With SGVaccRate (Date, Location, Continent, Total_Cases, Total_Deaths, Vaccinated_Percentage, Case_Fatality_Rate)
As
(
Select death.date AS 'Date', death.location, 
death.continent AS 'Continent', 
IsNull(death.total_cases, 0) AS 'Total Cases', 
IsNull(death.total_deaths, 0) AS 'Total Deaths', 
(cast(vac.people_fully_vaccinated as int)/death.population)*100 AS 'Vaccinated %',
((cast(death.total_deaths as int)/death.total_cases)*100) AS 'Case Fatality Rate'
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vac
	on death.location = vac.location
	and death.date = vac.date
Where death.continent is not null
and vac.people_fully_vaccinated is not null 
and death.location = 'Singapore'
)

Select *
From SGVaccRate
Order by Date

/* Creating views to store data for visualisation purposes */
Create View World_Rates As
(
Select date, location, 
IsNull(total_cases, 0) AS 'Total Cases', 
IsNull(total_deaths, 0) AS 'Total Death Count',
IsNull(((cast(total_deaths as int))/population),0)*100 AS 'Mortality Rate', 
IsNull(((cast(total_deaths as int)/total_cases)*100),0) AS 'Case Fatality Rate'
From PortfolioProject..CovidDeaths
Where continent is not null
)

Create View Asia As
(
Select date, continent, IsNull(Sum(new_cases),0) AS 'Total Cases', 
IsNull(Sum(cast(new_deaths as int)),0) AS 'Total Death Count', 
IsNull(Sum(((cast(new_deaths as int))/population)*100),0) AS 'Mortality Rate', 
IsNull((Sum((cast(new_deaths as int))/total_cases)*100),0) AS 'Case Fatality Rate'
From PortfolioProject..CovidDeaths
Where continent = 'Asia'
Group by continent, date
)

Create View SG As
(
Select date, location, 
total_cases AS 'Total Cases', 
IsNull(total_deaths, 0) AS 'Total Death Count',
IsNull(((cast(total_deaths as int))/population),0)*100 AS 'Mortality Rate', 
IsNull(((cast(total_deaths as int)/total_cases)*100),0) AS 'Case Fatality Rate'
From PortfolioProject..CovidDeaths
Where continent is not null and location = 'Singapore'
)

Create View SGVaccView
As
(
Select death.date AS 'Date', death.location, 
death.continent AS 'Continent', 
death.total_cases AS 'Total Cases', 
death.total_deaths AS 'Total Deaths', 
(cast(vac.people_fully_vaccinated as int)/death.population)*100 AS 'Vaccinated %',
((cast(death.total_deaths as int)/death.total_cases)*100) AS 'Case Fatality Rate'
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vac
	on death.location = vac.location
	and death.date = vac.date
Where death.continent is not null
and vac.people_fully_vaccinated is not null
and death.location = 'Singapore'
)

/* This query compares the mortality rate & death-case ratio against Asia's rates */
Select SG.date as 'Date',
SG.[Case Fatality Rate] As 'Case Fatality Rate (SG)',
Asia.[Case Fatality Rate] As 'Case Fatality Rate (Asia)'
From SG
Join Asia
  On SG.date = Asia.date
Order by SG.date

Select *
From SGVaccView
Order by Date

Select *
From SG
Order by date

Select *
From Asia
Order by date

Select *
From World_Rates
Order by location, date -- I will use this view to make comparisons of mortality and case fatality rates in Tableau
/* Map of Clusters */
Alter Table Clusters
Alter Column Total Decimal(10, 2);

Insert Into Clusters Values -- Splitting the KTV Cluster into 5 main KTV areas identified in the media to reflect different cluster spots
('Balestier Point', 0, 252),
('Tanglin Shopping Centre', 0, 252),
('Far East Shopping Centre',0,252),
('Golden Mile Complex',0,252),
('Textile Centre', 0,252);

Insert Into Clusters Values
('Jurong Fishery Port', 0.5, 1149),
('Hong Lim Market & Food Centre', 0.5,1149);

Delete From Clusters
Where Cluster = 'KTV lounges/clubs'

Delete From Clusters
Where Cluster = 'Jurong Fishery Port/ Hong Lim Market & Food Centre*'

SELECT Cluster, Total
FROM Clusters
WHERE Cluster NOT LIKE 'Case%'
Order by Total Desc
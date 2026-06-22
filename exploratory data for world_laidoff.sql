-- exploratoratory data analysis for world layoffs analysis
select * from layoffs_staging2;

-- the maximum of total laid off and percentage 
# after running the query i have found that the maximum amount of laid_off staffs is 12,000
# with a percentage laid of of 1. does that mean that all the staffs where laid off in a period of 3 years?
select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

-- getting the full details of all the industry whose percentage laid off is 1
select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- from the data it was found that 116 ccompanies laid off all their employees
with all_percentage_laidoff as(select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc)
select count(*) from all_percentage_laidoff;

-- this is to see the highest funding recieved by the highest laidoff companies which was in te britishvolt company with funds of 2.4 million dollars
select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

-- finding the total laid off in each company 
select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc; 

-- ordering by total_laid off
select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- getting the date of when the layoff started and when it stopped from our source
# layoff started in 2020-03-11 to 2023-03-06
select min(`date`), max(`date`)
from layoffs_staging2;

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2 desc;

select date, sum(total_laid_off)
from layoffs_staging2
group by `date`
order by 2 desc;

select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2 desc;

select substring(`date`, 1,7) as `month`, sum(total_laid_off)
from layoffs_staging2 
where substring(`date`, 1, 7)
group by `month`
order by 1 asc;

with rolling_total as (
select substring(`date`, 1,7) as `month`, sum(total_laid_off) as total_off
from layoffs_staging2 
where substring(`date`, 1, 7)
group by `month`
order by 1 asc)
select `month`, total_off, sum(total_off) over (order by `month`) as rolling_total
from rolling_total;

select company, YEAR(`date`), sum(total_laid_off) AS total_laid_off
from layoffs_staging2
group by company, year(`date`)
order by total_laid_off ; 

SELECT company, YEAR(`date`), SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;

with company_year (company, years, total_laid_off) as 
(SELECT company, YEAR(`date`), SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
) , company_year_rank as 
(select *,
dense_rank() over (partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
)
select *
from company_year_rank
where ranking <= 5;
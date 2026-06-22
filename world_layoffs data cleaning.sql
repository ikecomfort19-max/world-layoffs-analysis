-- data cleaning of layoffs

select * from layoffs;

-- 1. remove duplicates
-- 2. standardize the data 
-- 3. null values or blank values
-- 4. remove irrelevant columns
drop table layoffs_staging;
drop table layoffs_staging2;
-- first step. create another  and insert everything fromraw data to the new table
create table layoffs_staging like layoffs;
select * from layoffs_staging;

-- insert all data to new table
insert layoffs_staging
select * from layoffs;

-- removing duplicates
select *, row_number() over (partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging;

-- create a duplicate cte
with duplicate_cte as (select *, row_number() over (
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging)
select * from duplicate_cte 
where row_num > 1;

with duplicate_cte as (select *, row_number() over (
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging)
delete from duplicate_cte 
where row_num > 1;
delete from duplicate_cte where row_num > 1; #this didnt work because its not updatable
-- so to delete duplicates we do this instead. create a new table by creating a copy of layoff_staging and inserting all values from layof staging into the new table
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs_staging2;
insert into layoffs_staging2
select *, row_number() over (
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
;
select *
from layoffs_staging2 
where row_num > 1;

delete from layoffs_staging2 where row_num > 1;

select *
from layoffs_staging2
where row_num > 1;
select *
from layoffs_staging2;
#duplicates are removed

-- standardizing data means finding issues in your data and fixing it
select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

select distinct industry
from layoffs_staging2
order by 1; # 1 represents the first column

#from the industry data there has been some discrepancies in the spelling of crypto and cryptocurrency though they are on and same thing
#so it has to be fixed so that it wont be a problem during visualization

select * from layoffs_staging2
where industry like 'crypto%';

update layoffs_staging2
set industry = 'crypto'
where industry like 'crypto%';

select distinct location 
from layoffs_staging2
order by 1;

select distinct country, trim(trailing '.' from country) as trailed_country
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim(trailing '.' from country) 
where country like 'united states%';

select distinct country
from layoffs_staging2
order by 1;

select `date`,
str_to_date(`date`, '%m/%d/%Y') # helps change strings to date s
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

select `date`
from layoffs_staging2;
-- changing the character of date which was a text to date
alter table layoffs_staging2
modify column `date` date;

-- working with nulls and blank values
select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2
where industry is null or 
industry = '';

select * from layoffs_staging2
where company = 'airbnb';

select * from layoffs_staging2 t1
join #selfjoin
layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

select t1.industry, t2.industry 
from layoffs_staging2  t1
join #selfjoin
layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null 
and t2.industry is not null;


update layoffs_staging2
set industry = null
where industry = '';

select t1.industry, t2.industry 
from layoffs_staging2  t1
join #selfjoin
layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

-- removing irrelevant colunms and rows
select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- removing a column from a table
alter table  layoffs_staging2
drop column row_num;

select * from layoffs_staging2;


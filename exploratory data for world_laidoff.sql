-- ==============================================
-- WORLD LAYOFFS EXPLORATORY DATA ANALYSIS (EDA)
-- Dataset: World Layoffs (2020-2023)
-- Tool: MySQL Workbench
-- Author: Comfort Ike
-- Date: June 2026
-- ==============================================

-- ==============================================
-- SECTION 1: OVERVIEW
-- ==============================================

-- View the full cleaned dataset
SELECT * FROM layoffs_staging2;

-- ==============================================
-- SECTION 2: HIGH LEVEL SUMMARY
-- ==============================================

-- Finding: Maximum single layoff event was 12,000 employees
-- A percentage_laid_off of 1 means 100% of staff were laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Finding: Layoffs data spans from 2020-03-11 to 2023-03-06 (3 years)
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- ==============================================
-- SECTION 3: COMPANIES THAT SHUT DOWN (100% LAYOFF)
-- ==============================================

-- Finding: 116 companies laid off 100% of their employees
WITH all_percentage_laidoff AS (
  SELECT *
  FROM layoffs_staging2
  WHERE percentage_laid_off = 1
)
SELECT COUNT(*) AS total_shutdowns
FROM all_percentage_laidoff;

-- View all companies that shut down, ordered by size of layoff
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Finding: BritishVolt had the highest funding ($2.4 billion) 
-- among companies that fully shut down
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- ==============================================
-- SECTION 4: LAYOFFS BY COMPANY
-- ==============================================

-- Finding: Amazon, Google and Meta had the highest total layoffs
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- ==============================================
-- SECTION 5: LAYOFFS BY INDUSTRY
-- ==============================================

-- Finding: Consumer and Retail industries were hit hardest
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- ==============================================
-- SECTION 6: LAYOFFS BY COUNTRY
-- ==============================================

-- Finding: United States had by far the highest total layoffs
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- ==============================================
-- SECTION 7: LAYOFFS BY YEAR
-- ==============================================

-- Finding: 2022 had the highest layoffs overall
SELECT YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

-- ==============================================
-- SECTION 8: LAYOFFS BY COMPANY STAGE
-- ==============================================

-- Finding: Post-IPO companies had the highest layoffs
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- ==============================================
-- SECTION 9: MONTHLY LAYOFF TRENDS
-- ==============================================

-- Monthly breakdown of layoffs
SELECT SUBSTRING(`date`, 1, 7) AS `month`, 
  SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

-- ==============================================
-- SECTION 10: ROLLING TOTAL OF LAYOFFS
-- ==============================================

-- Finding: Shows cumulative growth of layoffs month by month
WITH rolling_total AS (
  SELECT SUBSTRING(`date`, 1, 7) AS `month`, 
    SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
  GROUP BY `month`
  ORDER BY 1 ASC
)
SELECT `month`, total_off,
  SUM(total_off) OVER (ORDER BY `month`) AS rolling_total
FROM rolling_total;

-- ==============================================
-- SECTION 11: TOP 5 COMPANIES WITH MOST LAYOFFS PER YEAR
-- ==============================================

-- Finding: Shows which companies dominated layoffs each year
WITH company_year AS (
  SELECT company, YEAR(`date`) AS years, 
    SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(`date`)
),
company_year_rank AS (
  SELECT *,
    DENSE_RANK() OVER (
      PARTITION BY years 
      ORDER BY total_laid_off DESC
    ) AS ranking
  FROM company_year
  WHERE years IS NOT NULL
)
SELECT *
FROM company_year_rank
WHERE ranking <= 5;

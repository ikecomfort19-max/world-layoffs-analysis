-- ==============================================
-- WORLD LAYOFFS DATA CLEANING
-- Dataset: World Layoffs (Raw)
-- Tool: MySQL Workbench
-- Author: Comfort Ike
-- Date: June 2026
-- Steps: 1) Remove Duplicates 2) Standardize Data
--        3) Handle NULL/Blank Values 4) Remove Irrelevant Columns
-- ==============================================

-- View raw data before cleaning
SELECT * FROM layoffs;

-- ==============================================
-- STEP 1: CREATE STAGING TABLE
-- Never work on raw data directly
-- Always create a copy to preserve the original
-- ==============================================

-- Create staging table with same structure as raw table
CREATE TABLE layoffs_staging LIKE layoffs;

-- Insert all raw data into staging table
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- Verify data was inserted correctly
SELECT * FROM layoffs_staging;

-- ==============================================
-- STEP 2: REMOVE DUPLICATES
-- ==============================================

-- First identify duplicates using ROW_NUMBER()
-- Any row with row_num > 1 is a duplicate
SELECT *, 
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, 
    total_laid_off, percentage_laid_off, `date`, 
    stage, country, funds_raised_millions
  ) AS row_num
FROM layoffs_staging;

-- View duplicates using CTE
WITH duplicate_cte AS (
  SELECT *, 
    ROW_NUMBER() OVER (
      PARTITION BY company, location, industry, 
      total_laid_off, percentage_laid_off, `date`, 
      stage, country, funds_raised_millions
    ) AS row_num
  FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- NOTE: Cannot delete directly from a CTE in MySQL
-- Solution: Create a second staging table with row_num column
-- Then delete rows where row_num > 1

-- Create layoffs_staging2 with an added row_num column
CREATE TABLE `layoffs_staging2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data with row numbers into staging2
INSERT INTO layoffs_staging2
SELECT *, 
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, 
    total_laid_off, percentage_laid_off, `date`, 
    stage, country, funds_raised_millions
  ) AS row_num
FROM layoffs_staging;

-- Verify duplicates are visible
SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- Delete all duplicate rows
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Confirm duplicates have been removed
SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- ==============================================
-- STEP 3: STANDARDIZE THE DATA
-- Fix inconsistencies in text, spelling and formats
-- ==============================================

-- 3a. Trim whitespace from company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- 3b. Fix industry name inconsistencies
-- Finding: 'Crypto' and 'Cryptocurrency' refer to same industry
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- View all crypto variations
SELECT * FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardize all crypto variations to 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 3c. Fix country name inconsistencies
-- Finding: 'United States' and 'United States.' are the same country
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) AS trimmed_country
FROM layoffs_staging2
ORDER BY 1;

-- Remove trailing period from United States
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Verify country names are now consistent
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- 3d. Convert date column from TEXT to proper DATE format
-- Finding: Date was stored as text (MM/DD/YYYY) — needs conversion
SELECT `date`,
  STR_TO_DATE(`date`, '%m/%d/%Y') AS formatted_date
FROM layoffs_staging2;

-- Update date values to proper date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change column data type from TEXT to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Verify date column is now properly formatted
SELECT `date` FROM layoffs_staging2;

-- ==============================================
-- STEP 4: HANDLE NULL AND BLANK VALUES
-- ==============================================

-- 4a. Identify rows where both key metrics are NULL
-- These rows have no useful data and can be removed later
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 4b. Find rows with NULL or blank industry values
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Example: Airbnb has missing industry — check if other Airbnb rows have it
SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';

-- 4c. Use self join to fill in missing industry values
-- Logic: If same company and location has industry elsewhere, use that value
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
  AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- First convert blank strings to NULL for consistency
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Now populate NULL industry values using self join
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Verify industry NULLs have been filled where possible
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
  AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- ==============================================
-- STEP 5: REMOVE IRRELEVANT ROWS AND COLUMNS
-- ==============================================

-- 5a. Remove rows where both total_laid_off 
-- and percentage_laid_off are NULL
-- These rows provide no analytical value
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 5b. Drop the row_num column — no longer needed
-- It was only used to identify and remove duplicates
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- ==============================================
-- FINAL CHECK: VIEW CLEANED DATASET
-- ==============================================

-- Dataset is now clean and ready for analysis
SELECT * FROM layoffs_staging2;

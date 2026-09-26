-- ============================================================
-- Netflix SQL Data Analysis Project
-- Database: MySQL 8+
-- Dataset: netflix_cleaned.csv
-- ============================================================

CREATE DATABASE IF NOT EXISTS netflix_analysis;
USE netflix_analysis;

-- ------------------------------------------------------------
-- 1. Create table
-- ------------------------------------------------------------
DROP TABLE IF EXISTS netflix_titles;

CREATE TABLE netflix_titles (
    show_id VARCHAR(20) PRIMARY KEY,
    type VARCHAR(20),
    title VARCHAR(255) NOT NULL,
    director TEXT,
    cast_members TEXT,
    country TEXT,
    date_added DATE,
    release_year INT,
    rating VARCHAR(20),
    duration VARCHAR(30),
    listed_in TEXT,
    description TEXT,
    added_year INT,
    added_month INT,
    added_month_name VARCHAR(20),
    duration_value DECIMAL(10,2),
    movie_duration DECIMAL(10,2),
    tv_seasons DECIMAL(10,2)
);

-- ------------------------------------------------------------
-- 2. Load the CSV
-- Put netflix_cleaned.csv in the same folder as this SQL file.
-- Enable LOCAL INFILE in your MySQL client if required.
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/netflix_cleaned.csv'
INTO TABLE netflix_titles
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, type, title, director, cast_members, country, date_added,
 release_year, rating, duration, listed_in, description,
 added_year, added_month, added_month_name, duration_value,
 movie_duration, tv_seasons);

-- ------------------------------------------------------------
-- 3. Data quality checks
-- ------------------------------------------------------------

-- Total records
SELECT COUNT(*) AS total_titles
FROM netflix_titles;

-- Duplicate IDs
SELECT show_id, COUNT(*) AS duplicate_count
FROM netflix_titles
GROUP BY show_id
HAVING COUNT(*) > 1;

-- Missing values by important column
SELECT
    SUM(title IS NULL OR title = '') AS missing_titles,
    SUM(type IS NULL OR type = '') AS missing_type,
    SUM(country IS NULL OR country = '') AS missing_country,
    SUM(rating IS NULL OR rating = '') AS missing_rating,
    SUM(date_added IS NULL) AS missing_date_added
FROM netflix_titles;

-- ------------------------------------------------------------
-- 4. Basic analysis
-- ------------------------------------------------------------

-- Movies vs TV Shows
SELECT
    type,
    COUNT(*) AS total_titles,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix_titles), 2) AS percentage
FROM netflix_titles
GROUP BY type
ORDER BY total_titles DESC;

-- Content added by year
SELECT
    added_year,
    COUNT(*) AS titles_added
FROM netflix_titles
WHERE added_year IS NOT NULL
GROUP BY added_year
ORDER BY added_year;

-- Content released by year
SELECT
    release_year,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year
ORDER BY release_year DESC;

-- Top release years
SELECT
    release_year,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year
ORDER BY total_titles DESC
LIMIT 10;

-- Ratings distribution
SELECT
    rating,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY rating
ORDER BY total_titles DESC;

-- ------------------------------------------------------------
-- 5. Movie analysis
-- ------------------------------------------------------------

-- Top 10 longest movies
SELECT
    title,
    movie_duration AS duration_minutes,
    release_year
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration IS NOT NULL
ORDER BY movie_duration DESC
LIMIT 10;

-- Average movie duration
SELECT
    ROUND(AVG(movie_duration), 2) AS average_movie_duration_minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration IS NOT NULL;

-- Shortest movies
SELECT
    title,
    movie_duration AS duration_minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration IS NOT NULL
ORDER BY movie_duration
LIMIT 10;

-- ------------------------------------------------------------
-- 6. TV Show analysis
-- ------------------------------------------------------------

-- TV shows with the most seasons
SELECT
    title,
    tv_seasons AS seasons,
    release_year
FROM netflix_titles
WHERE type = 'Tv Show'
  AND tv_seasons IS NOT NULL
ORDER BY tv_seasons DESC
LIMIT 10;

-- Average number of seasons
SELECT
    ROUND(AVG(tv_seasons), 2) AS average_tv_seasons
FROM netflix_titles
WHERE type = 'Tv Show'
  AND tv_seasons IS NOT NULL;

-- ------------------------------------------------------------
-- 7. Country analysis
-- Note: country contains comma-separated values in the source.
-- This query finds titles whose country field mentions a country.
-- ------------------------------------------------------------

SELECT
    country,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
  AND country <> 'Unknown'
GROUP BY country
ORDER BY total_titles DESC
LIMIT 20;

-- Titles associated with India
SELECT
    title,
    type,
    release_year,
    rating
FROM netflix_titles
WHERE country LIKE '%India%'
ORDER BY release_year DESC;

-- ------------------------------------------------------------
-- 8. Genre/category analysis
-- listed_in contains comma-separated categories.
-- ------------------------------------------------------------

SELECT
    listed_in,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE listed_in IS NOT NULL
  AND listed_in <> ''
GROUP BY listed_in
ORDER BY total_titles DESC
LIMIT 20;

-- Titles in the Drama category
SELECT
    title,
    type,
    release_year,
    rating
FROM netflix_titles
WHERE listed_in LIKE '%Drama%'
ORDER BY release_year DESC;

-- ------------------------------------------------------------
-- 9. Date analysis
-- ------------------------------------------------------------

-- Titles added by month
SELECT
    added_month,
    added_month_name,
    COUNT(*) AS titles_added
FROM netflix_titles
WHERE added_month IS NOT NULL
GROUP BY added_month, added_month_name
ORDER BY added_month;

-- Titles added in September
SELECT
    title,
    type,
    date_added
FROM netflix_titles
WHERE added_month = 9
ORDER BY date_added DESC;

-- ------------------------------------------------------------
-- 10. Business-style analysis
-- ------------------------------------------------------------

-- Number of titles added each year by content type
SELECT
    added_year,
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE added_year IS NOT NULL
GROUP BY added_year, type
ORDER BY added_year, type;

-- Content by release decade
SELECT
    CONCAT(FLOOR(release_year / 10) * 10, 's') AS release_decade,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY FLOOR(release_year / 10)
ORDER BY FLOOR(release_year / 10) DESC;

-- Most recent content
SELECT
    title,
    type,
    release_year,
    date_added
FROM netflix_titles
WHERE date_added IS NOT NULL
ORDER BY date_added DESC
LIMIT 20;

-- Oldest content in the catalog
SELECT
    title,
    type,
    release_year
FROM netflix_titles
ORDER BY release_year
LIMIT 20;

-- ------------------------------------------------------------
-- 11. Advanced SQL
-- ------------------------------------------------------------

-- Rank release years by number of titles
WITH yearly_content AS (
    SELECT release_year, COUNT(*) AS total_titles
    FROM netflix_titles
    GROUP BY release_year
)
SELECT
    release_year,
    total_titles,
    DENSE_RANK() OVER (ORDER BY total_titles DESC) AS year_rank
FROM yearly_content
ORDER BY year_rank, release_year DESC;

-- Year-over-year titles added
WITH yearly AS (
    SELECT
        added_year,
        COUNT(*) AS titles_added
    FROM netflix_titles
    WHERE added_year IS NOT NULL
    GROUP BY added_year
)
SELECT
    added_year,
    titles_added,
    LAG(titles_added) OVER (ORDER BY added_year) AS previous_year_titles,
    titles_added -
        LAG(titles_added) OVER (ORDER BY added_year) AS year_over_year_change
FROM yearly
ORDER BY added_year;

-- Average movie duration by release decade
SELECT
    CONCAT(FLOOR(release_year / 10) * 10, 's') AS release_decade,
    ROUND(AVG(movie_duration), 2) AS avg_movie_duration
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration IS NOT NULL
GROUP BY FLOOR(release_year / 10)
ORDER BY FLOOR(release_year / 10);

-- ------------------------------------------------------------
-- 12. Useful views for BI/reporting
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_content_summary AS
SELECT
    type,
    COUNT(*) AS total_titles,
    MIN(release_year) AS earliest_release_year,
    MAX(release_year) AS latest_release_year
FROM netflix_titles
GROUP BY type;

CREATE OR REPLACE VIEW vw_yearly_additions AS
SELECT
    added_year,
    type,
    COUNT(*) AS titles_added
FROM netflix_titles
WHERE added_year IS NOT NULL
GROUP BY added_year, type;

CREATE OR REPLACE VIEW vw_movie_metrics AS
SELECT
    COUNT(*) AS total_movies,
    ROUND(AVG(movie_duration), 2) AS avg_movie_duration,
    MIN(movie_duration) AS shortest_movie,
    MAX(movie_duration) AS longest_movie
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration IS NOT NULL;

CREATE OR REPLACE VIEW vw_tv_metrics AS
SELECT
    COUNT(*) AS total_tv_shows,
    ROUND(AVG(tv_seasons), 2) AS avg_seasons,
    MIN(tv_seasons) AS minimum_seasons,
    MAX(tv_seasons) AS maximum_seasons
FROM netflix_titles
WHERE type = 'Tv Show'
  AND tv_seasons IS NOT NULL;

-- Final summary
SELECT * FROM vw_content_summary;
SELECT * FROM vw_movie_metrics;
SELECT * FROM vw_tv_metrics;

/* =========================================================
   NETFLIX CONTENT ANALYTICS PROJECT
   Tools Used: SQL Server, Power BI
   Database: NetflixDB
========================================================= */

-----------------------------------------------------------
-- DATABASE SELECTION
-----------------------------------------------------------

USE NetflixDB;

-----------------------------------------------------------
-- VIEW RAW DATA
-----------------------------------------------------------

SELECT TOP 10 *
FROM netflix_titles;

SELECT COUNT(*) AS total_records
FROM netflix_titles;

SELECT *
FROM netflix_titles;

-----------------------------------------------------------
-- CHECK MISSING VALUES
-----------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(director) AS director_count,
    COUNT(cast) AS cast_count,
    COUNT(country) AS country_count,
    COUNT(date_added) AS date_added_count
FROM netflix_titles;

-----------------------------------------------------------
-- HANDLE NULL VALUES
-----------------------------------------------------------

UPDATE netflix_titles
SET
    director = ISNULL(director, 'unknown'),
    cast = ISNULL(cast, 'unknown'),
    country = ISNULL(country, 'unknown'),
    rating = ISNULL(rating, 'Not Rated');

-----------------------------------------------------------
-- VERIFY UPDATED DATA
-----------------------------------------------------------

SELECT *
FROM netflix_titles;

-----------------------------------------------------------
-- CHECK DUPLICATES
-----------------------------------------------------------

SELECT
    show_id,
    COUNT(*) AS duplicate_count
FROM netflix_titles
GROUP BY show_id
HAVING COUNT(*) > 1;

-----------------------------------------------------------
-- CONVERT DATE FORMAT
-----------------------------------------------------------

ALTER TABLE netflix_titles
ADD date_added_clean DATE;

UPDATE netflix_titles
SET date_added_clean = TRY_CONVERT(DATE, date_added);

-----------------------------------------------------------
-- EXTRACT YEAR & MONTH
-----------------------------------------------------------

ALTER TABLE netflix_titles
ADD year_added INT;

UPDATE netflix_titles
SET year_added = YEAR(date_added_clean);

ALTER TABLE netflix_titles
ADD month_added INT;

UPDATE netflix_titles
SET month_added = MONTH(date_added_clean);

-----------------------------------------------------------
-- EXTRACT DURATION DETAILS
-----------------------------------------------------------

ALTER TABLE netflix_titles
ADD duration_int INT,
    duration_type VARCHAR(20);

UPDATE netflix_titles
SET
    duration_int = TRY_CAST(
        LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT
    ),
    duration_type = RIGHT(
        duration,
        LEN(duration) - CHARINDEX(' ', duration)
    );

-----------------------------------------------------------
-- NORMALIZE COUNTRY DATA
-----------------------------------------------------------

SELECT
    show_id,
    TRIM(value) AS country
INTO netflix_country
FROM netflix_titles
CROSS APPLY STRING_SPLIT(country, ',');

-----------------------------------------------------------
-- NORMALIZE GENRE DATA
-----------------------------------------------------------

SELECT
    show_id,
    TRIM(value) AS genre
INTO netflix_genre
FROM netflix_titles
CROSS APPLY STRING_SPLIT(listed_in, ',');

-----------------------------------------------------------
-- CONTENT TYPE ANALYSIS
-----------------------------------------------------------

SELECT
    type,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY type;

-----------------------------------------------------------
-- TOP CONTENT-PRODUCING COUNTRIES
-----------------------------------------------------------

SELECT TOP 15
    country,
    COUNT(*) AS total
FROM netflix_country
GROUP BY country
ORDER BY total DESC;

-----------------------------------------------------------
-- CONTENT ADDED OVER TIME
-----------------------------------------------------------

SELECT
    year_added,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY year_added
ORDER BY year_added;

-----------------------------------------------------------
-- TOP GENRES ANALYSIS
-----------------------------------------------------------

SELECT TOP 10
    genre,
    COUNT(*) AS total
FROM netflix_genre
GROUP BY genre
ORDER BY total DESC;

-----------------------------------------------------------
-- MOVIES VS TV SHOWS OVER TIME
-----------------------------------------------------------

SELECT
    year_added,
    type,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY year_added, type
ORDER BY year_added;

-----------------------------------------------------------
-- AVERAGE MOVIE DURATION
-----------------------------------------------------------

SELECT
    AVG(duration_int) AS avg_duration
FROM netflix_titles
WHERE type = 'Movie';

-----------------------------------------------------------
-- CONTENT RATINGS DISTRIBUTION
-----------------------------------------------------------

SELECT
    rating,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY rating
ORDER BY total DESC;

-----------------------------------------------------------
-- FINAL VIEW FOR POWER BI
-----------------------------------------------------------

CREATE VIEW netflix_final AS
SELECT
    n.show_id,
    n.type,
    n.title,
    n.release_year,
    n.year_added,
    n.month_added,
    n.rating,
    n.duration_int,
    n.duration_type,
    c.country,
    g.genre
FROM netflix_titles n
LEFT JOIN netflix_country c
    ON n.show_id = c.show_id
LEFT JOIN netflix_genre g
    ON n.show_id = g.show_id;

-----------------------------------------------------------
-- VIEW FINAL DATASET
-----------------------------------------------------------

SELECT *
FROM netflix_final;
{{ config(
    materialized='table',
    file_format = 'delta',
    schema = 'gold'
) }}

WITH date_range AS (
    SELECT sequence(
        to_date('2005-01-01'), 
        to_date('2030-12-31'), 
        interval 1 day
    ) AS all_dates
)

SELECT * 
FROM (
    SELECT
        -- Date and primary key 
        CAST(date_format(date_col, 'yyyyMMdd') AS INT) AS date_PK,
        date_col AS date,
        date_format(date_col, 'EEEE, d MMMM yyyy') AS full_date_description,
        
        -- Year
        year(date_col) AS year,
        concat(year(date_col), '-Q', quarter(date_col)) AS year_quarter,
        concat(year(date_col), '-', lpad(cast(month(date_col) AS string), 2, '0')) AS year_month,
        
        --Quarter
        quarter(date_col) AS quarter,
        concat('Q', quarter(date_col)) AS quarter_name,
            
        --Month
        month(date_col) AS month,
        date_format(date_col, 'MMMM') AS month_name,
        date_format(date_col, 'MMM') AS month_name_short,
        
        -- week
        weekofyear(date_col) AS week,
        concat('W', weekofyear(date_col)) AS week_name,
        
        -- Day
        dayofyear(date_col) AS day_of_year,
        dayofmonth(date_col) AS day_of_month,
        ((dayofweek(date_col) + 5) % 7) + 1 AS day_of_week,
        date_format(date_col, 'EEEE') AS day_name,
        date_format(date_col, 'E') AS day_name_short,
        
        -- Fiscal Year
        year(date_col) AS fiscal_year,
        CASE WHEN month(date_col) <= 6 THEN 1 ELSE 2 END AS fiscal_half_year,
        quarter(date_col) AS fiscal_quarter,
        concat(year(date_col), '-Q', quarter(date_col)) AS fiscal_year_quarter,
        month(date_col) AS fiscal_month,
        date_format(date_col, 'MMMM') AS fiscal_month_name,
        concat(year(date_col), '-', lpad(cast(month(date_col) AS string), 2, '0')) AS fiscal_year_month,
        weekofyear(date_col) AS fiscal_week,
        dayofyear(date_col) AS fiscal_day_of_year,
        
        --Flags
        (((dayofweek(date_col) + 5) % 7) + 1 BETWEEN 1 AND 5) AS is_weekday,
        (((dayofweek(date_col) + 5) % 7) + 1 IN (6,7)) AS is_weekend,
        false AS is_holiday,
        date_col = last_day(date_col) AS is_end_of_month,
        date_col = trunc(date_col, 'quarter') AS is_start_of_quarter,
        date_col = last_day(add_months(trunc(date_col, 'quarter'), 2)) AS is_end_of_quarter,
        dayofyear(date_col) = 1 AS is_start_of_fiscal_year,
        date_col = make_date(year(date_col),12,31) AS is_end_of_fiscal_year,
        (month(date_col) IN (1,7)) AND (dayofmonth(date_col) = 1) AS is_start_of_fiscal_half_year,
        (month(date_col) IN (6,12)) AND (date_col = last_day(date_col)) AS is_end_of_fiscal_half_year,
        (month(date_col) IN (1,4,7,10) AND dayofmonth(date_col) = 1) AS is_start_of_fiscal_quarter,
        (month(date_col) IN (3,6,9,12)) AND (date_col = last_day(date_col)) AS is_end_of_fiscal_quarter,
        (year(date_col) % 4 = 0 AND (year(date_col) % 100 != 0 OR year(date_col) % 400 = 0)) AS is_leap_year

FROM date_range
LATERAL VIEW EXPLODE(all_dates) t AS date_col

UNION ALL

-- Special row for missing date
SELECT
    0 AS date_key,
    NULL AS date,
    'Giltigt datum saknas' AS full_date_description,
    0 AS year,
    'Giltigt datum saknas' AS year_quarter,
    'Giltigt datum saknas' AS year_month,
    0 AS quarter,
    'Giltigt datum saknas' AS quarter_name,
    0 AS month,
    'Giltigt datum saknas' AS month_name,
    'Giltigt datum saknas' AS month_name_short,
    0 AS week,
    'Giltigt datum saknas' AS week_name,
    0 AS day_of_year,
    0 AS day_of_month,
    0 AS day_of_week,
    'Giltigt datum saknas' AS day_name,
    'Giltigt datum saknas' AS day_name_short,
    0 AS fiscal_year,
    0 AS fiscal_half_year,
    0 AS fiscal_quarter,
    'Giltigt datum saknas' AS fiscal_year_quarter,
    0 AS fiscal_month,
    'Giltigt datum saknas' AS fiscal_month_name,
    'Giltigt datum saknas' AS fiscal_year_month,
    0 AS fiscal_week,
    0 AS fiscal_day_of_year,
    false AS is_weekday,
    false AS is_weekend,
    false AS is_holiday,
    false AS is_end_of_month,
    false AS is_start_of_quarter,
    false AS is_end_of_quarter,
    false AS is_start_of_fiscal_year,
    false AS is_end_of_fiscal_year,
    false AS is_start_of_fiscal_half_year,
    false AS is_end_of_fiscal_half_year,
    false AS is_start_of_fiscal_quarter,
    false AS is_end_of_fiscal_quarter,
    false AS is_leap_year
) d


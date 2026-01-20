{{ config(
    materialized = "view", 
    schema = 'silver'
) }}

WITH ranked AS (
    SELECT
        *, 
        ROW_NUMBER() OVER (
            PARTITION BY Key
            ORDER BY Date DESC
        ) AS rn
    FROM {{ source('bronze', 'trivec_combined') }}
), 

deduped AS (
    Select 
        * 
    from ranked
    Where rn = 1
)

SELECT
    *
FROM deduped
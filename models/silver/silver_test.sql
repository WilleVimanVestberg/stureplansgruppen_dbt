{{ config(
    materialized = "view"
) }}

SELECT * 
FROM {{ source('bronze', 'trivec_combined') }}


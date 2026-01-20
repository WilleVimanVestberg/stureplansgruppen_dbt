{{ config(
    materialized = "view"
) }}

WITH base AS (
    SELECT  
        product_key        AS product_PK,
        Product_FK,
        ProductName,
        ProductType,
        GroupKey,
        GroupName,
        -- Normaliserad nyckel
        LOWER(Product_FK) AS productnr_norm

    FROM {{ ref('fct_lines') }}
),

deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY productnr_norm
               ORDER BY product_PK
           ) AS rn
    FROM base
)

SELECT
    Product_FK AS product_PK,
    ProductName,
    ProductType,
    GroupKey,
    GroupName
FROM deduplicated
WHERE rn = 1
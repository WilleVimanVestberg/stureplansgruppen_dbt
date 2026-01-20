{{ config(
    materialized = "view",
    schema = 'gold'
) }}

WITH exploded AS (
    SELECT
        o.ticket_key,
        o.order_key,
        o.order_ts AS order_timestamp,
        o.ticket_update_number,
        o.order_date,
        o.TotalPrice,
        o.CenterNr,
        o.CenterName,
        o.Resturang,
        l.Key            AS line_key,
        l.ProductKey     AS product_key,
        l.ProductName,
        l.ProductType, 
        l.ProductNr,
        l.GroupKey,
        l.GroupName,
        l.Qty,
        l.Price,
        l.TotalInc,
        l.TotalEx,
        l.VatPerc
    FROM {{ ref('silver_orders') }} o
    LATERAL VIEW explode_outer(o.lines) exploded_lines AS l
),

add_order_updates AS (
    SELECT
    *,
    row_number() OVER (
        PARTITION BY order_key
        ORDER BY line_key
    ) AS order_update_number
FROM exploded
WHERE line_key IS NOT NULL
), 

normalized AS (
    SELECT
        *,
        LOWER(TRIM(ProductName)) AS normalized_name
    FROM add_order_updates
),

product_master AS (
    SELECT
        normalized_name,
        MIN(ProductNr) AS master_productnr
    FROM normalized
    GROUP BY normalized_name
), 

final AS (
    SELECT
        n.ticket_key,
        n.order_key,
        n.order_timestamp,
        n.ticket_update_number,
        n.order_date AS Date_FK,
        n.TotalPrice,
        n.CenterNr,
        n.CenterName,
        n.line_key,
        n.product_key,
        n.Resturang,
        n.normalized_name AS ProductName,
        n.ProductType,
        m.master_productnr AS Product_FK,
        n.GroupKey,
        CASE 
            WHEN LOWER(n.GroupName) LIKE '%vatten%' 
                OR LOWER(n.GroupName) LIKE '%läsk%' 
                OR LOWER(n.GroupName) LIKE '%alkoholfritt%' 
            THEN 'vatten, läsk, alkholfritt'
            ELSE n.GroupName
        END AS GroupName, 
        n.Qty,
        n.Price,
        n.TotalInc,
        n.TotalEx,
        n.VatPerc,
        n.order_update_number, 
        -- 🔑 Record hash på line-nivå
        {{ record_hash([
            'n.ticket_key',
            'n.order_key',
            'n.order_timestamp',
            'n.ticket_update_number',
            'n.order_date',
            'n.TotalPrice',
            'n.CenterNr',
            'n.CenterName',
            'n.line_key',
            'n.product_key',
            'n.Resturang',
            'n.normalized_name',
            'n.ProductType',
            'm.master_productnr',
            'n.GroupKey',
            'n.GroupName',
            'n.Qty',
            'n.Price',
            'n.TotalInc',
            'n.TotalEx',
            'n.VatPerc',
            'n.order_update_number'
        ]) }} AS line_PK
    FROM normalized n
    JOIN product_master m
      ON n.normalized_name = m.normalized_name
)

SELECT * FROM final;



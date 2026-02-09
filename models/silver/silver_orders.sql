{{ config(
    materialized = "view", 
    schema = 'silver'
) }}

-- stg_orders.sql
-- grain: one row per order

WITH exploded AS (
    SELECT
        k.Key AS ticket_key,
        k.TicketNr,
        k.ZNumber,
        k.ActualDate AS ticket_actual_date,
        k.Date AS ticket_date,
        k.Time AS ticket_time,
        k.CenterKey,
        k.CenterNr,
        k.CenterName,
        k.TotalPrice,
        k.TotalToPay,
        k.PrepStatus,
        k.ReceiptNr,
        k.Resturang,
        order.Key AS order_key,
        order.ActionId,
        order.ActualDate AS order_actual_date,
        order.Date AS order_date,
        order.Time AS order_time,
        order.UserKey AS order_user_key,
        order.UserName AS order_user_name,
        order.PcNr AS order_pc_nr,
        order.PcName AS order_pc_name,
        order.TableNr,
        order.TicketKey AS order_ticket_key,
        to_timestamp(concat(order.Date, ' ', order.Time),'yyyyMMdd HH:mm:ss') AS order_ts,
        order.Lines AS lines,
        order.Paymodes AS paymodes

    FROM {{ ref('silver_deduped') }} k
    LATERAL VIEW explode_outer(k.Orders) exploded_orders AS order
    -- OBS! INGEN rn-filter här
)

SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY ticket_key
        ORDER BY order_ts
    ) AS ticket_update_number
FROM exploded


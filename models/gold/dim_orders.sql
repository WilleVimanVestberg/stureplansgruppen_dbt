{{ config(
    materialized='table',
    file_format = 'delta',
    schema = 'gold'
) }}

WITH selected AS (
    SELECT
        ticket_key AS ticket_FK,
        TicketNr,
        ZNumber,
        ticket_actual_date,
        ticket_date,
        ticket_time,
        CenterKey,
        CenterNr,
        CenterName,
        TotalPrice,
        TotalToPay,
        PrepStatus,
        ReceiptNr,
        Resturang,
        order_key AS order_PK,
        ActionId,
        order_actual_date,
        order_date,
        order_time,
        order_user_key,
        order_user_name,
        order_pc_nr,
        order_pc_name,
        TableNr,
        order_ticket_key,
        order_ts, 
        coalesce(size(lines), 0) AS lines_count,
        coalesce(size(paymodes), 0) AS paymodes_count
    FROM {{ ref('silver_orders') }} 
)

SELECT
    *
FROM selected


{{ config(
    materialized = "view", 
    schema = 'gold'
) }}

SELECT
    o.ticket_key,
    o.order_key,
    o.order_ts AS order_timestamp,
    o.ticket_update_number,
    o.order_date,
    o.TotalPrice,
    o.CenterNr,
    o.CenterName,
    p.Key  AS paymode_key,
    p.PaymodeKey AS paymode_keyNr,
    p.PaymodeNr,
    p.PaymodeName,
    p.PaymodeType,
    p.TransactionId,
    p.TerminalId,
    p.Memo,
    p.GroupKey,
    p.GroupNr,
    p.GroupName,
    p.GroupLeftNr,
    p.GroupRightNr,
    p.Qty,
    p.Price,
    p.Total,
    p.Tip,
    p.TransactionCost
FROM {{ ref('silver_orders') }} o
LATERAL VIEW explode_outer(o.paymodes) exploded_lines AS p
WHERE p.Key IS NOT NULL

{{ config(
    materialized='table',
    file_format = 'delta',
    schema = 'gold'
) }}

SELECT 
    Key AS ticket_PK,
    TicketNr,
    ActualDate AS ticket_actual_date,
    Date AS ticket_date,
    Time AS ticket_time,
    CenterKey,
    CenterNr,
    CenterName,
    TotalPrice,
    TotalToPay,
    PrepStatus,
    ReceiptNr,
    Resturang
FROM {{ ref('silver_deduped') }}
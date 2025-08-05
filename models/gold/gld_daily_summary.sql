{{ config(materialized='table') }}

SELECT 
    transaction_date,
    COUNT(*) as total_transactions,
    SUM(amount_usd) as total_volume_usd,
    AVG(amount_usd) as avg_transaction_usd
FROM {{ ref('slv_transactions') }}
GROUP BY transaction_date
ORDER BY transaction_date DESC

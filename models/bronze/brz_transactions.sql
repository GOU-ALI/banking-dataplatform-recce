{{ config(materialized='view') }}

-- Simulating raw transaction data
SELECT 
    row_number() OVER () as transaction_id,
    'TXN-' || row_number() OVER () as reference,
    (random() * 1000)::numeric(10,2) as amount,
    CASE (random() * 2)::int 
        WHEN 0 THEN 'USD'
        ELSE 'EUR'
    END as currency,
    CURRENT_DATE - (random() * 30)::int as transaction_date
FROM generate_series(1, 100)

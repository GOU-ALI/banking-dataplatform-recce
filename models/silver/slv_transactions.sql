{{ config(materialized='table') }}

SELECT 
    transaction_id,
    reference,
    amount as original_amount,
    currency,
    -- Changed EUR rate to make difference visible
    CASE 
        WHEN currency = 'USD' THEN amount
        WHEN currency = 'EUR' THEN amount * 1.5  -- Big change for testing!
    END as amount_usd,
    transaction_date
FROM {{ ref('brz_transactions') }}
WHERE amount > 0

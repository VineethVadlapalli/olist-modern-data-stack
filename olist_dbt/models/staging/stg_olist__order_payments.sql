select
    md5(order_id || '-' || cast(payment_sequential as varchar)) as order_payment_key,
    order_id,
    cast(payment_sequential as integer)                         as payment_sequence,
    -- 3 rows carry 'not_defined'; treat as unknown rather than a real method
    nullif(payment_type, 'not_defined')                         as payment_type,
    cast(payment_installments as integer)                       as payment_installments,
    cast(payment_value as decimal(12, 2))                       as payment_value
from {{ source('olist', 'olist_order_payments_dataset') }}

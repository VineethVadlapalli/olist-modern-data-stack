-- One row per order: how it was paid.
select
    order_id,
    count(*)                                      as payment_count,
    sum(payment_value)                            as total_paid,
    max(payment_installments)                     as max_installments,
    arg_max(payment_type, payment_value)          as primary_payment_type,
    bool_or(payment_type = 'voucher')             as used_voucher
from {{ ref('stg_olist__order_payments') }}
group by 1

with orders   as (select * from {{ ref('int_orders__enriched') }}),
     items    as (select * from {{ ref('int_orders__items_summarised') }}),
     payments as (select * from {{ ref('int_orders__payments_summarised') }}),
     reviews  as (select * from {{ ref('stg_olist__order_reviews') }})

select
    orders.order_id,
    orders.customer_unique_id,
    orders.customer_id,
    orders.order_status,
    orders.order_purchased_at,
    cast(orders.order_purchased_at as date)                      as order_date,
    date_trunc('month', orders.order_purchased_at)::date         as order_month,
    orders.order_approved_at,
    orders.order_shipped_at,
    orders.order_delivered_at,
    orders.order_estimated_delivery_date,

    orders.customer_order_number,
    orders.customer_order_number = 1                             as is_first_order,

    coalesce(items.item_count, 0)                                as item_count,
    items.distinct_seller_count,
    coalesce(items.items_value, 0)                               as items_value,
    coalesce(items.freight_value, 0)                             as freight_value,
    coalesce(items.order_value, 0)                               as order_value,

    payments.payment_count,
    payments.total_paid,
    payments.primary_payment_type,
    payments.max_installments,
    coalesce(payments.used_voucher, false)                       as used_voucher,
    -- flags orders where what was paid differs from what was bought by more than 1 BRL
    -- (only when both sides exist: cancelled orders often have a payment but no items)
    coalesce(abs(payments.total_paid - items.order_value) > 1, false)
                                                                 as has_payment_mismatch,

    date_diff('day', orders.order_purchased_at, orders.order_delivered_at)
                                                                 as delivery_days,
    case
        when orders.order_delivered_at is null then null
        else cast(orders.order_delivered_at as date) > orders.order_estimated_delivery_date
    end                                                          as is_delivered_late,

    reviews.review_score,
    reviews.has_comment                                          as review_has_comment
from orders
left join items    using (order_id)
left join payments using (order_id)
left join reviews  using (order_id)

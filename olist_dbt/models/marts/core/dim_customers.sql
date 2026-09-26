-- One row per real person (customer_unique_id), not per order-level customer_id.
with orders as (
    select * from {{ ref('fct_orders') }}
    where order_status not in ('canceled', 'unavailable')
),

latest_location as (
    select
        o.customer_unique_id,
        arg_max(c.customer_city, o.order_purchased_at)            as customer_city,
        arg_max(c.customer_state, o.order_purchased_at)           as customer_state,
        arg_max(c.customer_zip_code_prefix, o.order_purchased_at) as customer_zip_code_prefix
    from {{ ref('fct_orders') }} o
    join {{ ref('stg_olist__customers') }} c using (customer_id)
    group by 1
),

order_stats as (
    select
        customer_unique_id,
        min(order_purchased_at)        as first_order_at,
        max(order_purchased_at)        as last_order_at,
        count(*)                       as order_count,
        sum(order_value)               as lifetime_value,
        avg(order_value)               as avg_order_value,
        avg(review_score)              as avg_review_score
    from orders
    group by 1
)

select
    loc.customer_unique_id,
    loc.customer_city,
    loc.customer_state,
    loc.customer_zip_code_prefix,
    geo.latitude,
    geo.longitude,
    stats.first_order_at,
    stats.last_order_at,
    date_trunc('month', stats.first_order_at)::date as cohort_month,
    coalesce(stats.order_count, 0)                 as order_count,
    coalesce(stats.lifetime_value, 0)              as lifetime_value,
    stats.avg_order_value,
    stats.avg_review_score,
    coalesce(stats.order_count, 0) > 1             as is_repeat_customer
from latest_location loc
left join order_stats stats using (customer_unique_id)
left join {{ ref('stg_olist__geolocation') }} geo
    on geo.zip_code_prefix = loc.customer_zip_code_prefix

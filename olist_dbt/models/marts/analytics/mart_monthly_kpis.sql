-- Business KPIs by month. The first (2016) and last (Sep/Oct 2018) months are sparse, so is_complete_month flags them.
with orders as (
    select * from {{ ref('fct_orders') }}
    where order_status not in ('canceled', 'unavailable')
)

select
    order_month,
    count(*)                                                       as orders,
    count(distinct customer_unique_id)                             as active_customers,
    count(*) filter (where is_first_order)                         as new_customers,
    round(sum(order_value), 2)                                     as gmv,
    round(avg(order_value), 2)                                     as avg_order_value,
    round(avg(review_score), 2)                                    as avg_review_score,
    round(avg(case when is_delivered_late then 1.0 else 0 end), 4) as late_delivery_rate,
    round(avg(delivery_days), 1)                                   as avg_delivery_days,
    order_month between '2017-01-01' and '2018-08-01'              as is_complete_month
from orders
group by 1
order by 1

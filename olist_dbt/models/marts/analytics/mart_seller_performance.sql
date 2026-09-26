with seller_orders as (
    select
        i.seller_id,
        i.order_id,
        sum(i.item_total)       as seller_order_value,
        any_value(o.review_score)       as review_score,
        any_value(o.is_delivered_late)  as is_delivered_late,
        any_value(o.delivery_days)      as delivery_days
    from {{ ref('fct_order_items') }} i
    join {{ ref('fct_orders') }} o using (order_id)
    where o.order_status not in ('canceled', 'unavailable')
    group by 1, 2
)

select
    s.seller_id,
    s.seller_state,
    count(*)                                                        as orders,
    round(sum(seller_order_value), 2)                               as gmv,
    round(avg(review_score), 2)                                     as avg_review_score,
    round(avg(case when is_delivered_late then 1.0 else 0 end), 4)  as late_delivery_rate,
    round(avg(delivery_days), 1)                                    as avg_delivery_days,
    rank() over (order by sum(seller_order_value) desc)             as gmv_rank
from seller_orders so
join {{ ref('dim_sellers') }} s using (seller_id)
group by 1, 2

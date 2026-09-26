-- Does late delivery drive bad reviews? Review score by how early/late the order arrived.
with delivered as (
    select
        review_score,
        date_diff('day', order_estimated_delivery_date, cast(order_delivered_at as date)) as days_vs_estimate
    from {{ ref('fct_orders') }}
    where order_status = 'delivered'
      and order_delivered_at is not null
      and review_score is not null
)

select
    case
        when days_vs_estimate <= -10 then '1. 10+ days early'
        when days_vs_estimate <= -1  then '2. 1-9 days early'
        when days_vs_estimate = 0    then '3. on the estimated day'
        when days_vs_estimate <= 7   then '4. 1-7 days late'
        else                              '5. 8+ days late'
    end                                                            as delivery_bucket,
    count(*)                                                       as orders,
    round(avg(review_score), 2)                                    as avg_review_score,
    round(avg(case when review_score <= 2 then 1.0 else 0 end), 4) as bad_review_rate
from delivered
group by 1
order by 1

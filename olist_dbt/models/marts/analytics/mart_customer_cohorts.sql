-- Monthly acquisition cohorts: how many customers from each first-purchase month come back in later months.
with orders as (
    select o.customer_unique_id, o.order_month, o.order_value, c.cohort_month
    from {{ ref('fct_orders') }} o
    join {{ ref('dim_customers') }} c using (customer_unique_id)
    where o.order_status not in ('canceled', 'unavailable')
),

cohort_sizes as (
    select cohort_month, count(*) as cohort_size
    from {{ ref('dim_customers') }}
    where cohort_month is not null
    group by 1
),

activity as (
    select
        cohort_month,
        date_diff('month', cohort_month, order_month) as months_since_first_order,
        count(distinct customer_unique_id)            as active_customers,
        sum(order_value)                              as revenue
    from orders
    group by 1, 2
)

select
    a.cohort_month,
    a.months_since_first_order,
    s.cohort_size,
    a.active_customers,
    round(a.active_customers / s.cohort_size, 4) as retention_rate,
    round(a.revenue, 2)                          as revenue,
    round(sum(a.revenue) over (
        partition by a.cohort_month order by a.months_since_first_order
    ) / s.cohort_size, 2)                        as cumulative_revenue_per_customer
from activity a
join cohort_sizes s using (cohort_month)

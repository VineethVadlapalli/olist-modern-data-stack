-- Monthly GMV in the KPI mart must add up to order-level value (no rows lost or double counted).
with mart as (select sum(gmv) as total from {{ ref('mart_monthly_kpis') }}),
     fct  as (
        select round(sum(order_value), 2) as total
        from {{ ref('fct_orders') }}
        where order_status not in ('canceled', 'unavailable')
     )
select mart.total, fct.total
from mart, fct
where abs(mart.total - fct.total) > 1

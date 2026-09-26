-- One row per order: what was bought.
select
    order_id,
    count(*)                          as item_count,
    count(distinct product_id)        as distinct_product_count,
    count(distinct seller_id)         as distinct_seller_count,
    sum(item_price)                   as items_value,
    sum(freight_value)                as freight_value,
    sum(item_price + freight_value)   as order_value
from {{ ref('stg_olist__order_items') }}
group by 1

{{
    config(
        materialized = 'incremental',
        unique_key = 'order_item_key',
        incremental_strategy = 'delete+insert'
    )
}}

select
    items.order_item_key,
    items.order_id,
    items.order_item_number,
    orders.customer_unique_id,
    items.product_id,
    items.seller_id,
    orders.order_purchased_at,
    orders.order_status,
    items.shipping_limit_at,
    items.item_price,
    items.freight_value,
    items.item_price + items.freight_value as item_total
from {{ ref('stg_olist__order_items') }} items
join {{ ref('int_orders__enriched') }} orders using (order_id)

{% if is_incremental() %}
-- only pick up orders newer than what is already loaded (3-day lookback for late-arriving rows)
where orders.order_purchased_at > (select max(order_purchased_at) - interval 3 day from {{ this }})
{% endif %}

-- Orders joined to the person who placed them, with purchase sequence per person.
with orders as (
    select o.*, c.customer_unique_id
    from {{ ref('stg_olist__orders') }} o
    join {{ ref('stg_olist__customers') }} c using (customer_id)
)

select
    *,
    row_number() over (
        partition by customer_unique_id order by order_purchased_at, order_id
    ) as customer_order_number
from orders

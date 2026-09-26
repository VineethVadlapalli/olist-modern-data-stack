-- An order cannot be delivered before it was purchased.
select order_id, order_purchased_at, order_delivered_at
from {{ ref('fct_orders') }}
where order_delivered_at < order_purchased_at

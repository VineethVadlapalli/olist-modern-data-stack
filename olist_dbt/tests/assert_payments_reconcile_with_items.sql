-- Data-quality check: paid amount should match items + freight.
-- The source has ~250 known mismatches; warn so they stay visible, fail if the number jumps.
{{ config(severity = 'error', warn_if = '>0', error_if = '>500') }}

select order_id, order_value, total_paid
from {{ ref('fct_orders') }}
where has_payment_mismatch

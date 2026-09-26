-- Every customer is active in their own first month, so month-0 retention must be 100%.
select cohort_month, retention_rate
from {{ ref('mart_customer_cohorts') }}
where months_since_first_order = 0
  and retention_rate <> 1

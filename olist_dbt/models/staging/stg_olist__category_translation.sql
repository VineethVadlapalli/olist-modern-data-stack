select product_category_name, product_category_name_english
from {{ source('olist', 'product_category_name_translation') }}

union all

-- categories missing from the source translation table
select product_category_name, product_category_name_english
from {{ ref('category_translation_patch') }}

select
    p.product_id,
    p.product_category_name                                              as category_name_pt,
    coalesce(t.product_category_name_english, 'unknown')                 as category_name,
    p.product_photo_count,
    p.product_weight_g,
    p.product_length_cm * p.product_height_cm * p.product_width_cm       as product_volume_cm3
from {{ ref('stg_olist__products') }} p
left join {{ ref('stg_olist__category_translation') }} t using (product_category_name)

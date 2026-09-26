select
    product_id,
    product_category_name,
    -- the source misspells "length" as "lenght"
    product_name_lenght        as product_name_length,
    product_description_lenght as product_description_length,
    product_photos_qty         as product_photo_count,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from {{ source('olist', 'olist_products_dataset') }}

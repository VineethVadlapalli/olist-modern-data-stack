select
    s.seller_id,
    s.seller_city,
    s.seller_state,
    s.seller_zip_code_prefix,
    geo.latitude,
    geo.longitude
from {{ ref('stg_olist__sellers') }} s
left join {{ ref('stg_olist__geolocation') }} geo
    on geo.zip_code_prefix = s.seller_zip_code_prefix

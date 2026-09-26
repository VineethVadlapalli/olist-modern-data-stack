-- ~1M raw rows collapse to one row per zip-code prefix (median coordinates are robust to bad points).
select
    lpad(cast(geolocation_zip_code_prefix as varchar), 5, '0') as zip_code_prefix,
    median(geolocation_lat)                                   as latitude,
    median(geolocation_lng)                                   as longitude,
    mode(upper(trim(geolocation_state)))                      as state,
    count(*)                                                  as source_point_count
from {{ source('olist', 'olist_geolocation_dataset') }}
group by 1

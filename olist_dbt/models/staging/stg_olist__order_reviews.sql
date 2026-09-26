-- Raw reviews are not unique: the same review_id can be attached to several orders,
-- and some orders received more than one review. Keep one review per order: the latest answered one.
with ranked as (
    select
        review_id,
        order_id,
        cast(review_score as integer)              as review_score,
        nullif(trim(review_comment_title), '')     as review_title,
        nullif(trim(review_comment_message), '')   as review_message,
        cast(review_creation_date as timestamp)    as review_created_at,
        cast(review_answer_timestamp as timestamp) as review_answered_at,
        row_number() over (
            partition by order_id
            order by review_answer_timestamp desc, review_id
        ) as review_rank
    from {{ source('olist', 'olist_order_reviews_dataset') }}
)

select
    review_id,
    order_id,
    review_score,
    review_title,
    review_message,
    review_message is not null as has_comment,
    review_created_at,
    review_answered_at
from ranked
where review_rank = 1

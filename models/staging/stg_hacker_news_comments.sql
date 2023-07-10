{{
    config(
        materialized='table'
    )
}}

with

raw_hacker_news_2022_11_15_sample as (
    select *
    from {{ ref('hacker_news_2022_11_15_sample') }}
),

final as (
    select
        id,
        text as content,
        timestamp as created_at,
        `by` as created_by
    from raw_hacker_news_2022_11_15_sample
)

select * from final

{{
    config(
        materialized='table'
    )
}}

with

stg_hacker_news_comments as (
    select *
    from {{ ref('stg_hacker_news_comments') }}
),

final as (
    select *
    from stg_hacker_news_comments
)

select * from final
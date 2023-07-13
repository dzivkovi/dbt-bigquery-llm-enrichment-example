{{
    config(
        materialized = 'incremental',
        unique_key = 'id',
        partition_by = {
            'field': 'created_at',
            'data_type': 'timestamp',
            'granularity': 'day'
        }
    )
}}

{% set start_date = "2022-11-15" %}
{% set max_rows_batch = 10 %}
{% set max_rows_total = 20 %}

{% set user_prompt = 'Moderate comment. Comment: "COMMENT"' %}
{% set system_prompt %}
You are agent moderating Hacker News comments left by users. You base your decision on rules provided below. You can either approve or reject a comment. If you reject a comment, you must provide a reason for your decision.

Rules:
- Promote Civility and Respect: Do not tolerate personal attacks, slurs, or any offensive language. Replace hostile comments with more respectful alternatives. Example: Replace offensive phrases like "Your coding style is terrible" with constructive criticisms such as "Improving indentation can make your code more readable."
- Prevent Spam and Self-Promotion: Users should not exploit comments for advertising their own work. Eliminate comments containing unrelated self-promotional links. Example: Remove comments where users drop unrelated links to their own blog or product in a data science discussion.
- Uphold Copyright Respect: Discourage plagiarism and unacknowledged use of others work. Remove or request proper citation for content that infringes on copyrights. Example: If a user posts a code snippet from Stack Overflow without credit, ask them to cite the source properly.
- Discourage False Information: Ensure users provide accurate and truthful information. Eliminate comments that misrepresent facts. Example: Correct or remove false statements like "JavaScript is a strongly typed language" unless they are clarified or backed by credible sources

Example input:
Moderate comment.
Comment: "This is a comment to moderate"

Example output (as a JSON):
{
    "decision": "YOUR_DECISION",
    "explanation": "YOUR_EXPLANATION"
}
where YOUR_DECISION is either "APPROVE" or "REJECT" and YOUR_EXPLANATION is a string
{% endset %}
{% set system_prompt_sanitized = system_prompt|escape|replace('\n', '') %}

-- Prepare the DDL statement to create the Remote Function
{% set create_function_ddl %}
create or replace function `{{ target.project }}.{{ target.dataset }}`.call_llm_model(prompt string) returns string
remote with connection `{{ target.project }}.us.cloud_resources_connection`
options (
    endpoint = "{{ var('call_llm_model_cloud_function_url') }}",
    max_batching_rows = {{ max_rows_batch }},
    user_defined_context = [
        ("system_prompt", "{{ system_prompt_sanitized }}"),
        ("model", "vertexai-palm")
    ]
)
{% endset %}

-- Execute the DDL statement to create the Remote Function
{% call statement(name, fetch_result=False) %}
    {{ create_function_ddl }}
{% endcall %}

with

-- source_table is a table that contains the data that we want to use to make predictions (features)
comments_batched as (
    select *
    from {{ ref('hacker_news_comments') }}
    where
        created_at >= '{{ start_date }}'
        {% if target.name == 'production' %}
            {% if is_incremental() %}
            and created_at >= coalesce((select max(created_at) from {{ this }}), '1900-01-01')
            {% endif %}
        {% endif %}
    order by created_at
    {% if target.name == 'production' %}
    limit {{ max_rows_total }}
    {% else %}
    limit 1 -- For testing purposes limit the number of rows to 1
    {% endif %}
),

user_prompt_added as (
    select
        *,
        replace('{{ user_prompt }}', "COMMENT", content) as prompt
    from comments_batched
),

enriched as (
    select
        *,
        `{{ target.project }}.{{ target.dataset }}`.call_llm_model(prompt) as response
    from user_prompt_added
),

final as (
    select
        * except (response),
        json_extract_scalar(response, "$.decision") as moderation_decision,
        json_extract_scalar(response, "$.explanation") as moderation_explanation
    from enriched
)

select * from final

{{
    config(
        materialized = 'incremental',
        unique_key = 'ad_spend_key',
        incremental_strategy = 'delete+insert'
    )
}}

{#
    Incremental on event_date with a lookback window rather than a plain
    "greater than the max date already loaded". The platform feeds land rows
    one to three days after the event, so a naive high-watermark would leave
    those rows permanently missing. The window re-processes the last N days on
    every run and delete+insert replaces them cleanly.

    Anything later than the window still needs a wider re-run:
        dbt run --select fct_ad_performance --vars '{spend_lookback_days: 30}'
#}

with spend as (

    select * from {{ ref('stg_ad_spend') }}

    {% if is_incremental() %}
    where event_date >= (
        select coalesce(max(event_date), date '1900-01-01')
                   - interval '{{ var("spend_lookback_days") }}' day
        from {{ this }}
    )
    {% endif %}

),

campaigns as (

    select * from {{ ref('stg_campaigns') }}

)

select
    s.ad_spend_key,
    cast(strftime(s.event_date, '%Y%m%d') as integer) as date_key,
    s.campaign_id  as campaign_key,
    c.channel_id   as channel_key,
    s.event_date,
    s.impressions,
    s.clicks,
    s.conversions,
    s.spend_gbp,
    s.loaded_at,
    date_diff('day', s.event_date, cast(s.loaded_at as date)) as load_lag_days

from spend s
inner join campaigns c
    on s.campaign_id = c.campaign_id

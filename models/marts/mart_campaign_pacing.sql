{{ config(materialized='table') }}

{#
    Budget pacing per campaign: how much of the booked budget has been spent
    against how far through the flight the campaign is. The gap between those
    two percentages is the number a client team actually looks at.
#}

with performance as (

    select
        campaign_key,
        min(event_date)      as first_active_date,
        max(event_date)      as last_active_date,
        count(*)             as active_days,
        sum(impressions)     as impressions,
        sum(clicks)          as clicks,
        sum(conversions)     as conversions,
        sum(spend_gbp)       as spend_gbp

    from {{ ref('fct_ad_performance') }}
    group by 1

),

campaigns as (

    select * from {{ ref('dim_campaign') }}

)

select
    c.campaign_key,
    c.campaign_name,
    c.client_name,
    c.channel_name,
    c.campaign_status,
    c.budget_gbp,
    c.start_date,
    c.end_date,
    p.active_days,
    p.impressions,
    p.clicks,
    p.conversions,
    p.spend_gbp,

    round(100.0 * p.spend_gbp / nullif(c.budget_gbp, 0), 1)              as budget_spent_pct,
    round(100.0 * p.active_days / nullif(c.flight_length_days, 0), 1)    as flight_elapsed_pct,
    round(1000.0 * p.spend_gbp / nullif(p.impressions, 0), 2)            as cpm_gbp,
    round(p.spend_gbp / nullif(p.clicks, 0), 2)                          as cpc_gbp,
    round(p.spend_gbp / nullif(p.conversions, 0), 2)                     as cpa_gbp,
    round(100.0 * p.clicks / nullif(p.impressions, 0), 3)                as ctr_pct

from campaigns c
inner join performance p
    on c.campaign_key = p.campaign_key

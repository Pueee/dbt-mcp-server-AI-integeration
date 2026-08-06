{{ config(materialized='table') }}

with campaigns as (

    select * from {{ ref('stg_campaigns') }}

),

channels as (

    select * from {{ ref('stg_channels') }}

)

select
    c.campaign_id as campaign_key,
    c.campaign_id,
    c.campaign_name,
    c.client_name,
    c.campaign_status,
    c.budget_gbp,
    c.start_date,
    c.end_date,
    c.flight_length_days,
    ch.channel_id as channel_key,
    ch.channel_id,
    ch.channel_name,
    ch.channel_group,
    ch.platform

from campaigns c
left join channels ch
    on c.channel_id = ch.channel_id

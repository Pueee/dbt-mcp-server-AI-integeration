{{ config(materialized='table') }}

select
    channel_id as channel_key,
    channel_id,
    channel_name,
    channel_group,
    platform

from {{ ref('stg_channels') }}

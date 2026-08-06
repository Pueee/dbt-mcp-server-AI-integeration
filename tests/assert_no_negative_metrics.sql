-- Singular test: impressions, clicks, conversions and spend are all counts or
-- amounts and can never be negative. Ad platform APIs do occasionally send
-- negative adjustment rows to claw back invalid traffic, so this is the kind
-- of thing that fails in production rather than in theory.

select
    ad_spend_key,
    event_date,
    campaign_key,
    impressions,
    clicks,
    conversions,
    spend_gbp

from {{ ref('fct_ad_performance') }}
where impressions < 0
   or clicks < 0
   or conversions < 0
   or spend_gbp < 0

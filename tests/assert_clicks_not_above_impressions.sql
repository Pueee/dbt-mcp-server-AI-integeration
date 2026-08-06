-- Singular test: a click cannot happen without an impression, so clicks above
-- impressions on the same row means the feed has joined something wrongly
-- upstream. Cheap to check, and it catches a class of bug that row counts and
-- uniqueness tests will not.

select
    ad_spend_key,
    event_date,
    campaign_key,
    impressions,
    clicks

from {{ ref('fct_ad_performance') }}
where clicks > impressions

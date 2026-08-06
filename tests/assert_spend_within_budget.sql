-- Singular test: no campaign should have spent more than 110% of its booked
-- budget. A little overdelivery is normal and tolerated; a long way past that
-- is either a pacing failure or a duplicated row in the fact table, and both
-- are worth failing a build over.

select
    campaign_key,
    campaign_name,
    budget_gbp,
    spend_gbp,
    budget_spent_pct

from {{ ref('mart_campaign_pacing') }}
where budget_spent_pct > 110

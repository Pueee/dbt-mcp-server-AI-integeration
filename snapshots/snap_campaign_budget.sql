{#
    Type 2 history on the attributes that get revised mid-flight. Budgets are
    topped up and campaigns are paused and restarted, and the source system
    overwrites in place, so without this the previous value is gone.

    check strategy rather than timestamp because the source has no reliable
    updated_at column, which is the usual situation with a booking system feed.
#}

{% snapshot snap_campaign_budget %}

{{
    config(
        unique_key = 'campaign_id',
        strategy = 'check',
        check_cols = ['budget_gbp', 'campaign_status', 'end_date']
    )
}}

select
    campaign_id,
    campaign_name,
    client_name,
    budget_gbp,
    campaign_status,
    start_date,
    end_date

from {{ ref('stg_campaigns') }}

{% endsnapshot %}

with source as (

    select * from {{ source('ad_platform', 'raw_ad_spend') }}

),

renamed as (

    select
        {{ generate_surrogate_key(['event_date', 'campaign_id']) }} as ad_spend_key,
        event_date,
        campaign_id,
        impressions,
        clicks,
        conversions,
        {{ pence_to_pounds('spend_pence') }} as spend_gbp,
        loaded_at

    from source

)

select * from renamed

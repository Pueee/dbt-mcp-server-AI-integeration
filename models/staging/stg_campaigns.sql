with source as (

    select * from {{ source('ad_platform', 'raw_campaigns') }}

),

renamed as (

    select
        campaign_id,
        campaign_name,
        client_name,
        channel_id,
        start_date,
        end_date,
        budget_gbp,
        upper(trim(status)) as campaign_status,
        date_diff('day', start_date, end_date) + 1 as flight_length_days

    from source

)

select * from renamed

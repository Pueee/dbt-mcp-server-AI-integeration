with source as (

    select * from {{ source('ad_platform', 'raw_channels') }}

),

renamed as (

    select
        channel_id,
        channel_name,
        channel_group,
        platform

    from source

)

select * from renamed

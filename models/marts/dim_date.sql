{{ config(materialized='table') }}

with date_spine as (

    select cast(range as date) as date_day
    from range(date '2026-01-01', date '2027-01-01', interval 1 day)

)

select
    cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
    date_day,
    extract(year from date_day)                   as calendar_year,
    extract(month from date_day)                  as calendar_month,
    strftime(date_day, '%B')                      as month_name,
    extract(quarter from date_day)                as calendar_quarter,
    extract(week from date_day)                   as iso_week,
    strftime(date_day, '%A')                      as day_name,
    extract(dow from date_day) in (0, 6)          as is_weekend

from date_spine

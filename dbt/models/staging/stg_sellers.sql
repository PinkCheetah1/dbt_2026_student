{# SESSION 3 - ON YOUR OWN (you do). The student repo gets this file with TODOs. #}

with source as (

    select * from {{ source('olist', 'sellers') }}

),

renamed as (

    select
        cast(seller_id              as varchar) as seller_id,
        cast(seller_zip_code_prefix as varchar) as zip_code_prefix,

        -- CLEAN: most cities are fine, but a few sellers typed extra junk:
        --   'auriflama/sp', 'sao paulo / sao paulo'  -> keep the part before the '/'
        --   '04482255', 'vendas@creditparts.com.br' -> not a city at all, so null
        -- (regexp_like must match the WHOLE value, hence the .* on both sides.)
        case
            when regexp_like(seller_city, '.*[0-9@].*') then null
            else lower(trim(split_part(seller_city, '/', 1)))
        end as city,

        upper(trim(seller_state)) as state

    from source

),

-- One row per seller. Already unique in the source; kept as the pattern.
deduplicated as (

    select * from renamed
    qualify row_number() over (
        partition by seller_id
        order by zip_code_prefix
    ) = 1

),

-- Nothing to derive.
derived as (

    select * from deduplicated

)

select * from derived
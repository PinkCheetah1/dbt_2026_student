{# SESSION 3 - TOGETHER (we do). The student repo gets this file with TODOs. #}

with source as (

    select * from {{ source('olist', 'customers') }}

),

renamed as (

    select
        cast(customer_id        as varchar) as customer_id,
        -- THE TRAP: `customer_id` is issued fresh for every order, so it is really
        -- an "order's customer" id. The actual person is `customer_unique_id`.
        cast(customer_unique_id as varchar) as customer_unique_id,

        -- Zip codes stay text: as a number, 01003 would lose its leading zero.
        cast(customer_zip_code_prefix as varchar) as zip_code_prefix,
        lower(trim(customer_city))                as city,
        upper(trim(customer_state))               as state

    from source

),

-- One row per customer_id. Already unique in the source; kept as the pattern.
deduplicated as (

    select * from renamed
    qualify row_number() over (
        partition by customer_id
        order by customer_unique_id
    ) = 1

),

-- Nothing to derive: every useful customer attribute is already a column.
derived as (

    select * from deduplicated

)

select * from derived
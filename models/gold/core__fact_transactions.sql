{{ config(
    materialized = 'view',
    persist_docs ={ "relation": true,
    "columns": true },
    tags = ['core']
) }}

SELECT
    block_number,
    block_hash,
    block_timestamp,
    tx_hash,
    nonce,
    POSITION,
    origin_function_signature,
    from_address,
    to_address,
    VALUE,
    tx_fee,
    gas_price,
    gas AS gas_limit,
    gas_used,
    cumulative_Gas_Used,
    input_data,
    tx_status AS status,
    max_fee_per_gas,
    max_priority_fee_per_gas,
    r,
    s,
    v,
    tx_type
FROM
    {{ ref('silver__transactions') }}

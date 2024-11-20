{{ config (
    materialized = "table",
    unique_key = "contract_address",
    tag = ["core"]
) }}

SELECT
    contract_address,
    'Aurora' AS blockchain,
    COUNT(*) AS events,
    MAX(block_number) AS latest_block,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    {{ ref('silver__logs') }}
GROUP BY
    1,
    2
HAVING
    COUNT(*) >= 25

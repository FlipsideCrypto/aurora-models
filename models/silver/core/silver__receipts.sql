-- depends_on: {{ ref('bronze__streamline_tx_receipts') }}
{{ config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = "receipts_id",
    cluster_by = "ROUND(block_number, -3)",
    tags = ['core']
) }}

WITH base AS (
    SELECT
        block_number,
        VALUE AS DATA,
        _inserted_timestamp
    FROM
{% if is_incremental() %}
{{ ref('bronze__streamline_tx_receipts') }}
WHERE
    _inserted_timestamp >= (
        SELECT
            MAX(_inserted_timestamp) _inserted_timestamp
        FROM
            {{ this }}
    )
    AND IS_OBJECT(
        DATA
    )
{% else %}
    {{ ref('bronze__streamline_FR_tx_receipts') }}
WHERE
    IS_OBJECT(
        DATA
    )
{% endif %}
),

blocks AS (
    SELECT 
        *
    FROM
    {{ ref('silver__blocks') }}
),

FINAL AS (
    SELECT
        b.block_number,
        blocks.block_timestamp,
        DATA :blockHash :: STRING AS block_hash,
        utils.udf_hex_to_int(
            DATA :blockNumber :: STRING
        ) :: INT AS blockNumber,
        utils.udf_hex_to_int(
            DATA :cumulativeGasUsed :: STRING
        ) :: INT AS cumulative_gas_used,
        DATA :from :: STRING AS from_address,
        utils.udf_hex_to_int(
            DATA :gasUsed :: STRING
        ) :: INT AS gas_used,
        DATA :logs AS logs,
        DATA :logsBloom :: STRING AS logs_bloom,
        utils.udf_hex_to_int(
            DATA :status :: STRING
        ) :: INT AS status,
        CASE
            WHEN status = 1 THEN TRUE
            ELSE FALSE
        END AS tx_success,
        CASE
            WHEN status = 1 THEN 'SUCCESS'
            ELSE 'FAIL'
        END AS tx_status,
        DATA :to :: STRING AS to_address1,
        CASE
            WHEN to_address1 = '' THEN NULL
            ELSE to_address1
        END AS to_address,
        DATA :transactionHash :: STRING AS tx_hash,
        utils.udf_hex_to_int(
            DATA :transactionIndex :: STRING
        ) :: INT AS POSITION,
        utils.udf_hex_to_int(
            DATA :type :: STRING
        ) :: INT AS TYPE,
        DATA :nearReceiptHash :: STRING AS near_receipt_hash,
        DATA :nearTransactionHash :: STRING AS near_transaction_hash,
        b._inserted_timestamp
    FROM
        base b
    LEFT JOIN blocks
        ON blocks.block_number = b.block_number
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['BLOCK_NUMBER', 'TX_HASH']) }} AS receipts_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id,    
    *
FROM
    FINAL
WHERE
    tx_hash IS NOT NULL qualify(ROW_NUMBER() over (PARTITION BY TX_HASH
ORDER BY
    _inserted_timestamp DESC)) = 1
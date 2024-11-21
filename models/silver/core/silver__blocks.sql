-- depends_on: {{ ref('bronze__streamline_blocks') }}
{{ config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = "block_number",
    cluster_by = "block_timestamp::date",
    tags = ['core']
) }}

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['block_number']
    ) }} AS block_id,
    block_number,
    utils.udf_hex_to_int(
        DATA :result :timestamp :: STRING
    ) :: TIMESTAMP AS block_timestamp,
    ARRAY_SIZE(
        DATA :result :transactions
    ) AS tx_count,
    utils.udf_hex_to_int(
        DATA :result :difficulty :: STRING
    ) :: INT AS difficulty,
    utils.udf_hex_to_int(
        DATA :result :totalDifficulty :: STRING
    ) :: INT AS total_difficulty,
    DATA :result :extraData :: STRING AS extra_data,
    utils.udf_hex_to_int(
        DATA :result :gasLimit :: STRING
    ) :: INT AS gas_limit,
    utils.udf_hex_to_int(
        DATA :result :gasUsed :: STRING
    ) :: INT AS gas_used,
    DATA :result :miner :: STRING AS miner,
    utils.udf_hex_to_int(
        DATA :result :nonce :: STRING
    ) :: INT AS nonce,
    DATA :result :parentHash :: STRING AS parent_hash,
    DATA :result :hash :: STRING AS HASH,
    DATA :result :receiptsRoot :: STRING AS receipts_root,
    utils.udf_hex_to_int(
        DATA :result :number :: STRING
    ) :: INT AS NUMBER,
    DATA :result :sha3Uncles :: STRING AS sha3_uncles,
    utils.udf_hex_to_int(
        DATA :result :size :: STRING
    ) :: INT AS SIZE,
    DATA :result :uncles AS uncles,
    DATA :result :logsBloom :: STRING AS logs_bloom,
    DATA :result :stateRoot :: STRING AS state_root,
    DATA :result :transactionsRoot :: STRING AS transactions_root,
    _partition_by_block_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM

{% if is_incremental() %}
{{ ref('bronze__streamline_blocks') }}
WHERE
    _inserted_timestamp >= (
        SELECT
            MAX(_inserted_timestamp) _inserted_timestamp
        FROM
            {{ this }}
    )
{% else %}
    {{ ref('bronze__streamline_FR_blocks') }}
{% endif %}

qualify(ROW_NUMBER() over (PARTITION BY block_number
ORDER BY
    _inserted_timestamp DESC)) = 1
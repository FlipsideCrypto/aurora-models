-- depends_on: {{ ref('bronze__blocks') }}
{{ config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = "block_number",
    cluster_by = "block_timestamp::date",
    tags = ['core','streamline_core_evm_realtime_step_2']
) }}

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['block_number']
    ) }} AS block_id,
    block_number,
    utils.udf_hex_to_int(
        DATA :timestamp :: STRING
    ) :: TIMESTAMP AS block_timestamp,
    ARRAY_SIZE(
        DATA :transactions
    ) AS tx_count,
    utils.udf_hex_to_int(
        DATA :difficulty :: STRING
    ) :: INT AS difficulty,
    utils.udf_hex_to_int(
        DATA :totalDifficulty :: STRING
    ) :: INT AS total_difficulty,
    DATA :extraData :: STRING AS extra_data,
    utils.udf_hex_to_int(
        DATA :gasLimit :: STRING
    ) :: INT AS gas_limit,
    utils.udf_hex_to_int(
        DATA :gasUsed :: STRING
    ) :: INT AS gas_used,
    DATA :miner :: STRING AS miner,
    utils.udf_hex_to_int(
        DATA :nonce :: STRING
    ) :: INT AS nonce,
    DATA :parentHash :: STRING AS parent_hash,
    DATA :hash :: STRING AS HASH,
    DATA :receiptsRoot :: STRING AS receipts_root,
    utils.udf_hex_to_int(
        DATA :number :: STRING
    ) :: INT AS NUMBER,
    DATA :sha3Uncles :: STRING AS sha3_uncles,
    utils.udf_hex_to_int(
        DATA :size :: STRING
    ) :: INT AS SIZE,
    DATA :uncles AS uncles,
    DATA :logsBloom :: STRING AS logs_bloom,
    DATA :stateRoot :: STRING AS state_root,
    DATA :transactionsRoot :: STRING AS transactions_root,
    partition_key as _partition_by_block_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM

{% if is_incremental() %}
{{ ref('bronze__blocks') }}
WHERE
    _inserted_timestamp >= (
        SELECT
            MAX(_inserted_timestamp) _inserted_timestamp
        FROM
            {{ this }}
    )
{% else %}
    {{ ref('bronze__blocks_fr') }}
{% endif %}

qualify(ROW_NUMBER() over (PARTITION BY block_number
ORDER BY
    _inserted_timestamp DESC)) = 1
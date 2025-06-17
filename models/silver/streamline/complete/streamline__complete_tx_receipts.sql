-- depends_on: {{ ref('bronze__receipts') }}
{{ config (
    materialized = "incremental",
    unique_key = "id",
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION on equality(id)",
    tags = ['streamline_core_evm_realtime_step_2']
) }}

SELECT
    MD5(
        CAST(
            COALESCE(CAST(CONCAT(block_number, '_-_', COALESCE(tx_hash, '')) AS text), '' :: STRING) AS text
        )
    ) AS id,
    block_number,
    tx_hash,
    _inserted_timestamp
FROM

{% if is_incremental() %}
{{ ref('bronze__receipts') }}
WHERE
    _inserted_timestamp >= (
        SELECT
            MAX(_inserted_timestamp) _inserted_timestamp
        FROM
            {{ this }}
    )
    AND tx_hash IS NOT NULL
{% else %}
    {{ ref('bronze__receipts_fr') }}
WHERE
    tx_hash IS NOT NULL
{% endif %}

qualify(ROW_NUMBER() over (PARTITION BY id
ORDER BY
    _inserted_timestamp DESC)) = 1

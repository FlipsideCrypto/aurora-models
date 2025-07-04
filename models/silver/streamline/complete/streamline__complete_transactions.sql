-- depends_on: {{ ref('bronze__transactions') }}
{{ config (
    materialized = "incremental",
    unique_key = "id",
    cluster_by = "ROUND(block_number, -3)",
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION on equality(id)",
    tags = ['streamline_core_evm_realtime']
) }}

SELECT
    MD5(
        CAST(
            COALESCE(CAST(block_number AS text), '' :: STRING) AS text
        )
    ) AS id,
    block_number,
    _inserted_timestamp
FROM

{% if is_incremental() %}
{{ ref('bronze__transactions') }}
WHERE
    _inserted_timestamp >= (
        SELECT
            MAX(_inserted_timestamp) _inserted_timestamp
        FROM
            {{ this }}
    )
{% else %}
    {{ ref('bronze__transactions_fr') }}
{% endif %}

qualify(ROW_NUMBER() over (PARTITION BY id
ORDER BY
    _inserted_timestamp DESC)) = 1

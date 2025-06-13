-- depends_on: {{ ref('bronze__traces') }}
{{ config (
    materialized = "incremental",
    unique_key = "id",
    cluster_by = "ROUND(block_number, -3)",
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION on equality(id)"
) }}

SELECT
    id,
    block_number,
    tx_hash,
    _inserted_timestamp
FROM

{% if is_incremental() %}
{{ ref('bronze__traces') }}
WHERE
    _inserted_timestamp >= 
    (
        SELECT
            ifnull(MAX(_inserted_timestamp),'1900-01-01' :: timestamp_ntz ) _inserted_timestamp
        FROM
            {{ this }}
    )
{% else %}
    {{ ref('bronze__traces_fr') }}
{% endif %}

qualify(ROW_NUMBER() over (PARTITION BY id
ORDER BY
    _inserted_timestamp DESC)) = 1

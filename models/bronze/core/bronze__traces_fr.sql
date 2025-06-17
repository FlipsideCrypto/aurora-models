{{ config (
    materialized = 'view',
    tags = ['bronze','core','streamline_v1','phase_1']
) }}

SELECT
    partition_key,
    block_number,
    tx_hash,
    VALUE,
    DATA,
    metadata,
    file_name,
    _inserted_timestamp
FROM
    {{ ref('bronze__traces_fr_v2') }}
UNION ALL
SELECT
    _partition_by_block_id AS partition_key,
    block_number,
    tx_hash,
    VALUE,
    DATA,
    metadata,
    file_name,
    _inserted_timestamp
FROM
   {{ ref('bronze__traces_fr_v1') }}
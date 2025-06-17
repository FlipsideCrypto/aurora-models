{{ config (
    materialized = 'view'
) }}

WITH meta AS (

    SELECT
        last_modified AS _inserted_timestamp,
        file_name,
        CAST(SPLIT_PART(SPLIT_PART(file_name, '/', 4), '_', 1) AS INTEGER) AS _partition_by_block_id
    FROM
        TABLE(
            information_schema.external_table_file_registration_history(
                start_time => GREATEST(DATEADD('day', -1, CURRENT_TIMESTAMP), '2023-08-01 18:44:00.000' :: timestamp_ntz),
                table_name => '{{ source( "bronze_streamline", "transactions") }}'
            )
        ) A
),
tbl AS (
    SELECT
        block_number,
        COALESCE(s.data :hash :: STRING, s.data :result :hash :: STRING) AS tx_hash,
        _inserted_timestamp,
        metadata,
        file_name,
        s._partition_by_block_id,
        s.value AS VALUE,
        s.data AS DATA
    FROM
        {{ source(
            "bronze_streamline",
            "transactions"
        ) }}
        s
        JOIN meta b
        ON b.file_name = metadata$filename
        AND b._partition_by_block_id = s._partition_by_block_id
    WHERE
        b._partition_by_block_id = s._partition_by_block_id
        AND (
            DATA :error :code IS NULL
            OR DATA :error :code NOT IN (
                '-32000',
                '-32001',
                '-32002',
                '-32003',
                '-32004',
                '-32005',
                '-32006',
                '-32007',
                '-32008',
                '-32009',
                '-32010'
            )
        )
)
SELECT
    block_number,
    COALESCE(f.value :hash :: STRING, tx_hash) AS tx_hash,
    _inserted_timestamp,
    MD5(
        CAST(
            COALESCE(
                CAST(
                    CONCAT(
                        block_number,
                        '_-_',
                        COALESCE(COALESCE(f.value :hash :: STRING, tx_hash), '')
                    ) AS text
                ),
                '' :: STRING
            ) AS text
        )
    ) AS id,
    data,
    metadata,
    file_name,
    _partition_by_block_id,
    _inserted_timestamp,
    COALESCE(f.value, tbl.data:result, tbl.data) AS VALUE
FROM
    tbl,
    LATERAL FLATTEN(
        input => VALUE :data :result :transactions, OUTER => TRUE
    ) f
WHERE f.value IS NOT NULL OR tbl.data :transactionIndex IS NOT NULL 
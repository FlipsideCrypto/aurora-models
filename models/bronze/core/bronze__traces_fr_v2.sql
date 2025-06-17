{{ config (
    materialized = 'view',
    tags = ['bronze','core','streamline_v1','phase_1']
) }}

    WITH meta AS (
        SELECT
            registered_on AS _inserted_timestamp,
            file_name,
            CAST(SPLIT_PART(SPLIT_PART(file_name, '/', 4), '_', 1) AS INTEGER ) AS partition_key
        FROM
            TABLE(
                information_schema.external_table_files(
                    table_name => '{{ source( "bronze_streamline", "traces_by_hash") }}'
                )
            ) A
    )
SELECT
    s.*,
    b.file_name,
    b._inserted_timestamp,
    COALESCE(
        s.value :"BLOCK_NUMBER" :: STRING,
        s.value :"block_number" :: STRING,
        s.metadata :request :"data" :id :: STRING,
        PARSE_JSON(
            s.metadata :request :"data"
        ) :id :: STRING
    ) :: INT AS block_number,
    s.value: "TX_HASH" :: STRING AS tx_hash
FROM
    {{ source( "bronze_streamline", "traces_by_hash") }}
    s
    JOIN meta b
    ON b.file_name = metadata$filename
    AND b.partition_key = s.partition_key
WHERE
    b.partition_key = s.partition_key
    AND DATA :error IS NULL
    AND DATA IS NOT NULL
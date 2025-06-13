{{ config (
    materialized = "view",
    post_hook = fsc_utils.if_data_call_function_v2(
        func = 'streamline.udf_bulk_rest_api_v2',
        target = "{{this.schema}}.{{this.identifier}}",
        params ={ "external_table" :'blocks_transactions',
        "sql_limit" :"30000",
        "producer_batch_size" :"30000",
        "worker_batch_size" :"10000",
        "sql_source" :'{{this.identifier}}',
        "exploded_key": tojson(['result', 'result.transactions']) }
    ),
    tags = ['streamline_core_evm_realtime']
) }}

SELECT
    150815373 as block_number,
    ROUND(block_number, -3) AS partition_key,
    live.udf_api(
        'POST',
        '{URL}',
        OBJECT_CONSTRUCT(
            'Content-Type', 'application/json',
            'fsc-quantum-state', 'streamline'
        ),
        OBJECT_CONSTRUCT(
            'id', block_number,
            'jsonrpc', '2.0',
            'method', 'eth_getBlockByNumber',
            'params', ARRAY_CONSTRUCT(utils.udf_int_to_hex(block_number), TRUE)
        ),
        'Vault/prod/evm/aurora/mainnet'
    ) AS request
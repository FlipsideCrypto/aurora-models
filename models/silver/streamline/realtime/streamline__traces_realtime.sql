{{ config (
    materialized = "view",
    post_hook = fsc_utils.if_data_call_function_v2(
        func = 'streamline.udf_bulk_rest_api_v2',
        target = "{{this.schema}}.{{this.identifier}}",
        params ={ 
            "external_table" :'traces',
            "sql_limit" :"30000",
            "producer_batch_size" :"30000",
            "worker_batch_size" :"10000",
            "sql_source" :'{{this.identifier}}',
            "exploded_key": tojson(['result']) 
        }
    ),
    tags = ['streamline_core_evm_realtime']
) }}

SELECT
    150949168 as block_number,
    '0x967586085f70584ab5e5886ba9c7d1b2f227f554ed594a491978e4a2110bfdd7' as tx_hash,
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
            'method', 'debug_traceTransaction',
            'params', ARRAY_CONSTRUCT(tx_hash, OBJECT_CONSTRUCT('tracer', 'callTracer', 'timeout', '120s'))
        ),
        'Vault/prod/evm/aurora/mainnet'
    ) AS request
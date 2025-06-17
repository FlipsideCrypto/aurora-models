{{ config (
    materialized = "view",
    post_hook = fsc_utils.if_data_call_function_v2(
        func = 'streamline.udf_bulk_rest_api_v2',
        target = "{{this.schema}}.{{this.identifier}}",
        params ={ 
            "external_table" :'traces_by_hash',
            "sql_limit" :"12000",
            "producer_batch_size" :"12000",
            "worker_batch_size" :"4000",
            "sql_source" :'{{this.identifier}}' 
        }
    ),
    tags = ['streamline_core_evm_realtime_step_2']
) }}

with txs as (
    select 
        block_number,
        tx_hash
    from {{ ref('silver__transactions') }}
    where block_number >= (select block_number from {{ ref('_block_lookback') }})
    except
    select 
        block_number,
        tx_hash
    from {{ ref('streamline__complete_traces') }}
    where block_number >= (select block_number from {{ ref('_block_lookback') }})
)

SELECT
    block_number,
    tx_hash,
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
from txs

order by block_number desc

limit 12000
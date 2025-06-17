{{ config (
    materialized = "view",
    tags = ['streamline_core_evm_realtime']
) }}

SELECT
    _id,
    (
        (6000 / 60) * 5
    ) :: INT AS block_number_delay, --minute-based block delay
    (_id - block_number_delay) :: INT AS block_number,
    utils.udf_int_to_hex(block_number) AS block_number_hex
FROM
    {{ ref('admin__number_sequence') }}
WHERE
    _id <= (
        SELECT
            COALESCE(
                block_number,
                0
            )
        FROM
            {{ ref("streamline__get_chainhead") }}
    )
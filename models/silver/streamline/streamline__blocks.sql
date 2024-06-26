{{ config (
    materialized = "view",
    tags = ['streamline_view']
) }}

{% if execute %}
    {% set height = run_query('SELECT streamline.udf_get_chainhead()') %}
    {% set block_height = height.columns [0].values() [0] %}
{% else %}
    {% set block_height = 0 %}
{% endif %}

SELECT
    height AS block_number,
    REPLACE(
        concat_ws('', '0x', to_char(height, 'XXXXXXXX')),
        ' ',
        ''
    ) AS block_number_hex
FROM
    TABLE(
        streamline.udtf_get_base_table(
            {{ block_height }}
            - 800
        )
    ) -- avoid the missing blocks at the tips of the chainhead, around 1 hour

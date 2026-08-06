{#
    Ad platforms report spend in minor currency units. Converting in one place
    means the rounding rule is defined once rather than in every model that
    touches spend.
#}

{% macro pence_to_pounds(column_name, decimal_places=2) -%}

    round(cast({{ column_name }} as decimal(18,4)) / 100, {{ decimal_places }})

{%- endmacro %}

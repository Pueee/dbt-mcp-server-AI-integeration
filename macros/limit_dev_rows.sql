{#
    Caps rows in dev so a full build stays cheap. Does nothing when the target
    is prod. Trivial here on DuckDB; the same pattern is what keeps a BigQuery
    dev environment from scanning production volumes on every run.
#}

{% macro limit_dev_rows(days=30) -%}

    {%- if target.name == 'dev' and var('apply_dev_limit', false) -%}
        where event_date >= current_date - interval '{{ days }}' day
    {%- endif -%}

{%- endmacro %}

{#
    Builds a deterministic hash key from a list of columns.

    dbt_utils ships an equivalent macro. It is written out longhand here so the
    project runs without package dependencies, and because the null handling is
    worth being explicit about: an unhandled null would silently collapse two
    different business keys onto the same hash.
#}

{% macro generate_surrogate_key(field_list) -%}

    {%- set fields = [] -%}
    {%- for field in field_list -%}
        {%- do fields.append("coalesce(cast(" ~ field ~ " as varchar), '_dbt_null_')") -%}
    {%- endfor -%}

    md5({{ fields | join(" || '-' || ") }})

{%- endmacro %}

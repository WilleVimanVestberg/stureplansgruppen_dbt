{% macro record_hash(columns) %}
    {% set cols = [] %}
    {% for col in columns %}
        {% do cols.append("COALESCE(CAST(" ~ col ~ " AS STRING), '')") %}
    {% endfor %}
    -- Skapar en hash av de angivna kolumnerna
    md5(CONCAT({{ cols | join(", ") }}))
{% endmacro %}

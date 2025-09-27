{% macro show_raw_tables() %}
  {% set query %}
    SHOW TABLES FROM raw
  {% endset %}
  
  {% set results = run_query(query) %}
  
  {% if results %}
    {% for row in results %}
      {{ log("Table: " ~ row[0], info=True) }}
    {% endfor %}
  {% endif %}
{% endmacro %}
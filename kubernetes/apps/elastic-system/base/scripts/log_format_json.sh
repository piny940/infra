curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_index_template/log_format_json" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"fluentd.*\"],
  \"template\": {
    \"mappings\": {
      \"properties\": {
        \"log\": {
          \"type\": \"object\"
        }
      }
    }
  }
}

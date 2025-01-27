# ログの自動削除
curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_ilm/policy/logs_auto_delete" -H 'Content-Type: application/json' -d"
{
  \"policy\": {
    \"phases\": {
      \"delete\": {
        \"min_age\": \"${LOGS_TTL}\",
        \"actions\": {
          \"delete\": {}
        }
      }
    }
  }
}"
curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_index_template/logstash_template" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"fluentd.*\"],
  \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"logs_auto_delete\"
    }
  }
}"

# logのフォーマットをjsonに変更
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

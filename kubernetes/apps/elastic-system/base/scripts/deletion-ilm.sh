# create ilm policy
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
  \"index_patterns\": [\"logstash-*\"],
  \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"logs_auto_delete\"
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_ilm/policy/delete_in_two_days" -H 'Content-Type: application/json' -d"
{
  \"policy\": {
    \"phases\": {
      \"delete\": {
        \"min_age\": \"2d\",
        \"actions\": {
          \"delete\": {}
        }
      }
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_index_template/kube_apiserver_template" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"fluentd.kube_apiserver.*\"],
  \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"delete_in_two_days\"
    }
  }
}"


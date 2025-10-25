# create ilm policy
curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_ilm/policy/prd_logs_auto_delete" -H 'Content-Type: application/json' -d"
{
  \"policy\": {
    \"phases\": {
      \"delete\": {
        \"min_age\": \"${LOGS_PRD_TTL}\",
        \"actions\": {
          \"delete\": {}
        }
      }
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_index_template/kubernetes_production" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"kubernetes.production.*\"],
  \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"prd_logs_auto_delete\"
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_ilm/policy/stg_logs_auto_delete" -H 'Content-Type: application/json' -d"
{
  \"policy\": {
    \"phases\": {
      \"delete\": {
        \"min_age\": \"${LOGS_STG_TTL}\",
        \"actions\": {
          \"delete\": {}
        }
      }
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_index_template/kubernetes_staging" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"kubernetes.staging.*\"],
  \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"stg_logs_auto_delete\"
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_ilm/policy/monitoring_logs_auto_delete" -H 'Content-Type: application/json' -d"
{
  \"policy\": {
    \"phases\": {
      \"delete\": {
        \"min_age\": \"${LOGS_MONITORING_TTL}\",
        \"actions\": {
          \"delete\": {}
        }
      }
    }
  }
}"

curl -X PUT -k -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "https://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_index_template/monitoring" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"fluentd.logs.*\", \"grafana.logs.*\"],
  \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"monitoring_logs_auto_delete\"
    }
  }
}"

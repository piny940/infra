#!/bin/bash

set -e

# Vault login
export VAULT_ADDR="https://vault.piny940.com"
vault login -method=oidc role=monitoring

# Grafana
vault kv get -mount="monitoring" -format="json" "grafana" \
  | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' > ./grafana/.env
echo "ELASTICSEARCH_PASSWORD=\"${ELASTICSEARCH_PASSWORD}\"" >> ./grafana/.env

# NGINX
mkdir -p ./nginx/secrets
vault kv get -mount="monitoring" -field="tls.crt" "tls" > ./nginx/secrets/tls.crt
vault kv get -mount="monitoring" -field="tls.key" "tls" > ./nginx/secrets/tls.key

# Fluent Bit
echo "ELASTICSEARCH_PASSWORD=" > ./fluentbit/.env

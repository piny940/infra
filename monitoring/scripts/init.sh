#!/bin/bash

set -e

# Vault login
export VAULT_ADDR="https://vault.piny940.com"
vault login -method=oidc role=monitoring

# Grafana
cp ./grafana/.env.sample ./grafana/.env
vault kv get -mount="monitoring" -format="json" "grafana" \
  | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' >> ./grafana/.env

# NGINX
mkdir -p ./nginx/secrets
vault kv get -mount="monitoring" -field="tls.crt" "tls" > ./nginx/secrets/tls.crt
vault kv get -mount="monitoring" -field="tls.key" "tls" > ./nginx/secrets/tls.key

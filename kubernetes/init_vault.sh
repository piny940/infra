kubectl exec vault-0 -n vault -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > ~/cluster-keys.json

VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ~/cluster-keys.json)
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
export VAULT_ADDR=https://vault.example.com
jq -r ".root_token" ~/cluster-keys.json | vault login

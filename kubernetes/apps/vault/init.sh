# コマンドは1つずつ実行する
kubectl exec vault-0 -n vault -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > ~/cluster-keys.json

VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ~/cluster-keys.json)
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
export VAULT_ADDR=https://vault.piny940.com
jq -r ".root_token" ~/cluster-keys.json | vault login -
vault auth enable kubernetes
export SA_SECRET_NAME=$(kubectl get secrets -n vault --output=json \
    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
export SA_JWT_TOKEN=$(kubectl get secret -n vault $SA_SECRET_NAME \
    --output 'go-template={{ .data.token }}' | base64 --decode)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')
vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT" \
    issuer="https://kubernetes.default.svc.cluster.local"
vault policy write k8s-cluster - <<EOF
path "k8s/*" {
  capabilities = ["read", "list"]
}
EOF
vault write auth/kubernetes/role/k8s-cluster \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=vault \
    policies=k8s-cluster \
    ttl=24h

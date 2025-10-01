# Vault

参考: https://qiita.com/piny940/items/66214e8f7c8af18ba014

## CLI をインストール(初回のみ)

[kubernetes/README.md](../..//README.md) を参照。

## Vault サーバーの起動

### 証明書の設定

環境変数を設定

```bash
export VAULT_K8S_NAMESPACE="vault"
export VAULT_HELM_RELEASE_NAME="vault"
export VAULT_SERVICE_NAME="vault"
export K8S_CLUSTER_NAME="cluster.local"
export WORKDIR="/tmp/vault-keys"
mkdir -p ${WORKDIR}
```

秘密鍵を生成

```bash
openssl genrsa -out ${WORKDIR}/vault.key 2048
```

CSR を作成

```bash
cat > ${WORKDIR}/vault-csr.conf <<EOF
[req]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha256
distinguished_name = kubelet_serving
req_extensions = v3_req
[ kubelet_serving ]
O = system:nodes
CN = system:node:*.${VAULT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${VAULT_SERVICE_NAME}
DNS.2 = *.${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}
DNS.3 = *.${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc
DNS.4 = *.${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc.cluster.local
DNS.5 = ${VAULT_SERVICE_NAME}
DNS.6 = ${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}
DNS.7 = ${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc
DNS.8 = ${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF
openssl req -new -key ${WORKDIR}/vault.key -out ${WORKDIR}/vault.csr -config ${WORKDIR}/vault-csr.conf
```

証明書を発行

```bash
cat | kubectl create -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
   name: vault.svc
spec:
   signerName: kubernetes.io/kubelet-serving
   expirationSeconds: 8640000
   request: $(cat ${WORKDIR}/vault.csr|base64|tr -d '\n')
   usages:
   - digital signature
   - key encipherment
   - server auth
EOF
```

Approve

```bash
kubectl certificate approve vault.svc
```

証明書から secret を作成

```bash
kubectl get csr vault.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/vault.crt
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${WORKDIR}/vault.ca
kubectl create secret generic vault-tls -n $VAULT_K8S_NAMESPACE --from-file=vault.key=${WORKDIR}/vault.key --from-file=vault.crt=${WORKDIR}/vault.crt --from-file=vault.ca=${WORKDIR}/vault.ca
```

### サーバーの設定

初回のみ、ローカルから鍵をアップロード

```bash
env=staging
scp "$env"-cluster-keys.json procyon:cluster-keys.json
```

<!-- ```bash
CLUSTER_KEY=$(kubectl exec vault-0 -n vault -- vault operator init \
                -key-shares=1 \
                -key-threshold=1 \
                -format=json)
if [ -z "${CLUSTER_KEY}" ]; then
echo "CLUSTER_KEY is not set"
fi
echo $CLUSTRE_KEY > ~/cluster-keys.json
``` -->

prefix を設定

```bash
source .env
export K8S_ENV
PREFIX=""
if [ $K8S_ENV == "staging" ]; then
PREFIX="stg-"
fi
```

unseal（Pod を再起動するたびに実行する）

```bash
VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ~/cluster-keys.json)
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
```

### 認証周りの設定

ログイン：

```bash
ROOT_TOKEN=$(jq -r ".root_token" ~/cluster-keys.json)
kubectl exec vault-0 -n vault -- vault login $ROOT_TOKEN
```

初回のみ、kubernetes の認証を有効にする

```bash
kubectl exec vault-0 -n vault -- \
vault auth enable kubernetes
```

kubernetes の認証を設定

```bash
SA_SECRET_NAME=$(kubectl get secrets -n vault --output=json \
    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
SA_JWT_TOKEN=$(kubectl get secret -n vault $SA_SECRET_NAME \
    --output 'go-template={{ .data.token }}' | base64 --decode)
SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
 --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')
kubectl exec vault-0 -n vault -- \
  vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT" \
    issuer="https://kubernetes.default.svc.cluster.local"
```

## WebUI にログイン

`jq -r ".root_token" ~/cluster-keys.json`でトークンを取得し、ログインする。

## Kubernetes 向けの Role を設定

```bash
vault policy write k8s-cluster - <<EOF
path "k8s/*" {
capabilities = ["read", "list"]
}
EOF
vault policy write issuer - <<EOF
path "pki_int/sign/cluster-local" {
capabilities = ["create", "update"]
}
EOF
vault write auth/kubernetes/role/k8s-cluster \
 bound_service_account_names=vault-auth \
 bound_service_account_namespaces=vault \
 policies=k8s-cluster \
 ttl=24h
vault write auth/kubernetes/role/issuer \
 audience="vault://vault-issuer" \
 bound_service_account_names=vault-issuer \
 bound_service_account_namespaces=vault \
 policies=issuer \
 ttl=24h
```

## Secret Engine を作成

`Secret Engines`から`K/V`を選択し、`k8s`という名前で作成する。

## PIK の設定

PKI を有効にする。

```bash
WORKDIR="/tmp/vault"
vault secrets enable pki
vault secrets tune -max-lease-ttl=43800h pki
```

Root 証明書を作成

```bash
vault write pki/root/generate/internal common_name="root" issuer_name="root" ttl=87600h > ${WORKDIR}/root_ca.crt
vault write pki/config/urls issuing_certificates="https://vault.vault:8200/v1/pki/ca" crl_distribution_points="https://vault.vault:8200/v1/pki/crl"
vault write pki/roles/vault-vault allowed_domains=vault.vault allow_subdomains=false max_ttl=72h
```

中間証明書の CSR を作成

```bash
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -format=json pki_int/intermediate/generate/internal common_name="Vault Intermediate Authority" issuer_name="vault-intermediate" | jq -r '.data.csr' > ${WORKDIR}/pki_intermediate.csr
vault write pki_int/config/urls issuing_certificates="https://vault.vault.svc.cluster.local:8200/v1/pki/ca" crl_distribution_points="https://vault.vault.svc.cluster.local:8200/v1/pki/crl"
vault write -format=json pki/root/sign-intermediate issuer_ref="root" csr=@${WORKDIR}/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > ${WORKDIR}/intermediate.cert.pem
vault write pki_int/intermediate/set-signed certificate=@${WORKDIR}/intermediate.cert.pem
vault write pki_int/roles/cluster-local issuer_ref="$(vault read -field=default pki_int/config/issuers)"  allowed_domains="svc.cluster.local" allow_subdomains=true max_ttl="720h"
```

## Admin ユーザーを作成

root アカウントだと危険なので、admin ユーザーを作成する。

`Policies` > 'Create ACL Policy' で以下のポリシーを作成する。

```hcl
path "k8s/*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}
path "pki/*" {
  capabilities = ["read", "list"]
}
path "pki_int/*" {
  capabilities = ["read", "list"]
}
```

ローカルPCで自分のGoogleのsubを確認

```sh
gcloud auth print-identity-token
```

GCPでGoogle Auth Platformのクライアントを作成。
承認済みRedirectURIは `https://${prefix}vault.piny940.com/ui/vault/auth/oidc/oidc/callback`

```sh
CLIENT_ID={クライアントID}
CLIENT_SECRET={クライアントシークレット}
GOOGLE_SUB={自分のGoogleアカウントのsub}
ENV={staging | production}
```

以下を実行。

```sh
if [ "$ENV" = "staging" ]; then
  CALLBACK=https://stg-vault.piny940.com/ui/vault/auth/oidc/oidc/callback
else
  CALLBACK=https://vault.piny940.com/ui/vault/auth/oidc/oidc/callback
fi
kubectl exec vault-0 -n vault -- \
vault auth enable oidc
kubectl exec vault-0 -n vault -- \
  vault write auth/oidc/config \
    oidc_discovery_url="https://accounts.google.com" \
    oidc_client_id="$CLIENT_ID" \
    oidc_client_secret="$CLIENT_SECRET" \
    default_role="admin"
kubectl exec vault-0 -n vault -- \
  vault auth tune \
    -default-lease-ttl=86400s \
    -listing-visibility=unauth \
  oidc/
kubectl exec vault-0 -n vault -- \
  vault write auth/oidc/role/admin \
    name="admin" \
    role_type="oidc" \
    user_claim="sub" \
    bound_subject="$GOOGLE_SUB" \
    allowed_redirect_uris="$CALLBACK" \
    token_policies="admin"
```

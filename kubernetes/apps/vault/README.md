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
export VAULT_INTERNAL_SERVICE_NAME="vault-internal"
export K8S_CLUSTER_NAME="cluster.local"
export WORKDIR="/tmp/vault"
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
DNS.5 = *.${VAULT_INTERNAL_SERVICE_NAME}
DNS.6 = *.${VAULT_INTERNAL_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}
DNS.7 = *.${VAULT_INTERNAL_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc
DNS.8 = *.${VAULT_INTERNAL_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc.cluster.local
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

証明書を取得

```bash
kubectl get csr vault.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/vault.crt
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${WORKDIR}/vault.ca
```

secret を作成

```bash
kubectl create secret generic vault-ha-tls -n $VAULT_K8S_NAMESPACE --from-file=vault.key=${WORKDIR}/vault.key --from-file=vault.crt=${WORKDIR}/vault.crt --from-file=vault.ca=${WORKDIR}/vault.ca
```

### サーバーの設定

初回のみ：

```bash
CLUSTER_KEY=$(kubectl exec vault-0 -n vault -- vault operator init \
                -key-shares=1 \
                -key-threshold=1 \
                -format=json)
if [ -z "${CLUSTER_KEY}" ]; then
echo "CLUSTER_KEY is not set"
fi
echo $CLUSTRE_KEY > ~/cluster-keys.json
```

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

vault にログイン

```bash
export VAULT_ADDR="https://${PREFIX}vault.piny940.com"
jq -r ".root_token" ~/cluster-keys.json | vault login -
```

初回のみ、kubernetes の認証を有効にする。

```bash
vault auth enable kubernetes
```

kubernetes の認証を設定

```bash
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
path "k8s/\*" {
capabilities = ["read", "list"]
}
EOF
vault write auth/kubernetes/role/k8s-cluster \
 bound_service_account_names=vault-auth \
 bound_service_account_namespaces=vault \
 policies=k8s-cluster \
 ttl=24h
```

## WebUI にログイン

`jq -r ".root_token" ~/cluster-keys.json`でトークンを取得し、ログインする。

## Secret Engine を作成

`Secret Engines`から`K/V`を選択し、`k8s`という名前で作成する。

## Admin ユーザーを作成

root アカウントだと危険なので、admin ユーザーを作成する。

`Policies` > 'Create ACL Policy' で以下のポリシーを作成する。

```hcl
path "k8s/*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}
```

`k8s/`以下のリソースに対して、全ての操作が可能なポリシーになっている。

`Access` > `Enable new method`で`Userpass`を有効にする。
`Path`は適当で OK

ユーザーを作成する。

- `Generated Token's Policies`は先程作成したものを選択する。
- `Generated Token's Initial TTL`は`86400`(24h)にする。

これで、admin ユーザーが作成される。

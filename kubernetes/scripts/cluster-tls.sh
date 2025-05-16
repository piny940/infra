external_secret() {
  app=$1
  echo "apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: cluster-tls
  namespace: $app
spec:
  secretStoreRef:
    name: vault-secret-store
    kind: ClusterSecretStore
  refreshInterval: 24h
  data:
    - secretKey: tls.crt
      remoteRef:
        key: cluster-tls
        property: tls.crt
    - secretKey: tls.key
      remoteRef:
        key: cluster-tls
        property: tls.key" > certificates/${app}.yaml
}

namespaces=$(cat namespaces/namespaces.yaml| grep -A 2 "kind: Namespace" - | grep "name:" | awk '{print $2}')
for namespace in $namespaces; do
  if [ ! -e "certificates/$namespace.yaml" ]; then
    external_secret $namespace
  fi
  if ! yq '.resources[]' certificates/kustomization.yaml | grep -q $namespace; then
    yq -i ".resources += [\"$namespace.yaml\"]" certificates/kustomization.yaml
  fi
done

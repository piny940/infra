kustomization() {
  env=$1

  echo "apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: helm-alert
  namespace: flux-system
spec:
  summary: \"Helm alert\"
  eventMetadata:
    env: ${env}
    cluster: \"home-cluster\"
    region: \"kyoto/japan\"
  providerRef:
    name: githubdispatch
  eventSeverity: info
  eventSources:"
}

for env in 'staging'; do
  path=apps/flux-alerts/staging/helm-alert.yaml
  kustomization ${env} > ${path}
  for ns in `cat namespaces/namespaces.yaml | grep name: | cut -c 9-`; do
    echo "    - kind: HelmRelease
      name: \"*\"
      namespace: ${ns}" >> ${path}
  done
done

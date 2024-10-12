kubectl create configmap -n velero velero-workload-identity-credential-configuration --from-file=velero/staging/gcp-credential-configuration.json
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero --namespace velero --values velero/base/values.yaml --values velero/staging/values.yaml --version 6.7.0

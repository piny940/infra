helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero --namespace velero --values velero/base/values.yaml --values velero/production/values.yaml --version 8.1.0

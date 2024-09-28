helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero --namespace velero --values velero/values.yaml --version 6.7.0

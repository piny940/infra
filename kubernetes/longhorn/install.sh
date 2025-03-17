helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --values longhorn/values.yaml --version 1.8.1

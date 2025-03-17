if [ -z "$env" ]; then
  echo "env is not set"
  exit 1
fi
version=$(yq eval .spec.chart.spec.version apps/longhorn/base/helm.yaml)

echo env = "$env"
echo version = "$version"

helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --values apps/longhorn/base/values.base.yaml --values apps/longhorn/"$env"/values.yaml --version "$version"

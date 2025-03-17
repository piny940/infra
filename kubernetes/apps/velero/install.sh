if [ -z "$env" ]; then
  echo "env is not set"
  exit 1
fi

echo env = "$env"

echo "Add velero repository"
repo_name=$(yq eval .metadata.name apps/velero/base/repo.yaml)
repo_url=$(yq eval .spec.url apps/velero/base/repo.yaml)

echo "repo_name = $repo_name"
echo "repo_url = $repo_url"

helm repo add "$repo_name" "$repo_url"

echo "Install velero"
version=$(yq eval .spec.chart.spec.version apps/velero/base/helm.yaml)
chart_name=$(yq eval .spec.chart.spec.chart apps/velero/base/helm.yaml)
app_name=$(yq eval .metadata.name apps/velero/base/helm.yaml)

echo version = "$version"

helm install "$app_name" "$repo_name"/"$chart_name" --namespace velero --values apps/velero/base/values.base.yaml --values apps/velero/"$env"/values.yaml --version "$version"

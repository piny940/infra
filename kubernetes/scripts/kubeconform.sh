# build manifests for all apps
for env in production staging
do
  for app in $(ls apps/)
  do
    mkdir -p tmp/kubeconform/manifests/"$app"
    kustomize build apps/"$app"/"$env"/ > tmp/kubeconform/manifests/"$app"/"$env".yaml
  done
done

# CRD Schemaが見つからない場合は追加する：https://github.com/piny940/CRDs-catalog
kubeconform -summary \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/piny940/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -schema-location "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json" \
  -output json \
  -strict \
  -ignore-missing-schemas \
  tmp/kubeconform/manifests/

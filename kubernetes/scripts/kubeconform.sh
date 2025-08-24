go run scripts/pkustomize/main.go

# CRD Schemaが見つからない場合は追加する：https://github.com/piny940/CRDs-catalog
kubeconform -summary \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/piny940/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -schema-location "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json" \
  -output json \
  -strict \
  /tmp/pkustomize/out

if [ -z "$1" ]; then
  echo "Usage: create-app.sh <app-name>"
  exit 1
fi

mkdir -p apps/$1
mkdir -p apps/$1/base
mkdir -p apps/$1/staging
mkdir -p apps/$1/production

cat <<EOF > apps/$1/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: []
# configMapGenerator:
#   - name: $1-conf
#     literals: []
EOF

cat <<EOF > apps/$1/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: $1
resources:
  - ../base
labels:
  - pairs:
      env: production
    includeSelectors: true
# configMapGenerator:
#   - name: $1-conf
#     behavior: merge
#     literals: []
EOF

cat <<EOF > apps/$1/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: $1
namePrefix: stg-
resources:
  - ../base
labels:
  - pairs:
      env: staging
    includeSelectors: true
# configMapGenerator:
#   - name: $1-conf
#     behavior: merge
#     literals: []
EOF

cat <<EOF >> namespaces/namespaces.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: $1
EOF

sh scripts/flux-kustomize.sh

echo "App $1 created!"

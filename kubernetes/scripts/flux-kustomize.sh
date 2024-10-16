kustomization() {
  app=$1
  path=$2
  source=$3

  echo "apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ${app}
  namespace: flux-system
spec:
  interval: 3m
  path: ./kubernetes/${path}
  prune: true
  sourceRef:
    kind: GitRepository
    name: ${source}
    namespace: flux-system" 
}

createKustomization() {
  app=$1
  env=$2
  file_path="_flux/$env/kustomizations/$app.yaml"

  # すでにKustomizationが存在する場合
  if [ -e $file_path ]; then
    return
  fi

  # StagingとProductionの区別がない場合
  if [ ! -e "./apps/$app/base" ]; then
    kustomization $app "apps/$app" "flux-system" > $file_path
    return
  fi

  # $envディレクトリが存在しない場合は何もしない
  if [ ! -e "./apps/$app/$env" ]; then
    return
  fi

  target="apps/$app/$env"
  if [ $env = "staging" ]; then
    source="apps-git"
  else
    source="flux-system"
  fi
  kustomization $app $target $source > $file_path
}

for env in staging production; do
  if [ ! -e "_flux/$env/kustomizations/namespaces.yaml" ]; then
    kustomization "namespaces" "namespaces" > _flux/$env/kustomizations/namespaces.yaml
  fi
done
for dir in `ls -d apps/*/`; do
  # apps/xx/ -> xx
  app=$(echo $dir | sed -e 's:apps/::g' | sed -e 's:/::g')

  for env in staging production; do
    if [ ! -e "_flux/$env/kustomizations/$app.yaml" ]; then
      createKustomization $app $env
    fi
  done
done

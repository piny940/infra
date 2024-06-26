kustomization() {
  app=$1
  path=$2

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
    name: flux-system
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
  if [ ! -e "./apps/$app/production" ]; then
    kustomization $app "apps/$app" > $file_path
    return
  fi

  # Baseがない場合はまだ非対応
  if [ ! -e "./apps/$app/base" ]; then
    return
  fi

  # $envディレクトリが存在しない場合はProductionをデプロイ
  if [ ! -e "./apps/$app/$env" ]; then
    target="apps/$app/production"
  else
    target="apps/$app/$env"
  fi

  kustomization $app $target > $file_path
}

for env in staging production; do
  rm -f _flux/$env/kustomizations/*.yaml
  kustomization "namespaces" "namespaces" > _flux/$env/kustomizations/namespaces.yaml
done
for dir in `ls -d apps/*/`; do
  # apps/xx/ -> xx
  app=$(echo $dir | sed -e 's:apps/::g' | sed -e 's:/::g')

  for env in staging production; do
    createKustomization $app $env
  done
done

kubectl -n flux-system delete secret flux-system

source .env
export GITHUB_USER
export GITHUB_TOKEN

flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --token-auth \
  --owner=piny940 \
  --repository=infra \
  --branch=main \
  --path=kubernetes/flux \
  --read-write-key \
  --personal

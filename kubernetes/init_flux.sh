#!/bin/bash

kubectl -n flux-system delete secret flux-system

source .env
export K8S_ENV

flux bootstrap git \
  --components-extra=image-reflector-controller,image-automation-controller \
  --url=ssh://git@github.com:piny940/infra.git \
  --branch=main \
  --private-key-file=~/.ssh/ed25519 \
  --path=kubernetes/_flux/${K8S_ENV}

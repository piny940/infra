#!/bin/bash

kubectl -n flux-system delete secret flux-system

source .env
export K8S_ENV

if [ -z "${K8S_ENV}" ]; then
  echo "K8S_ENV is not set"
  exit 1
fi

flux bootstrap git \
  --components-extra=image-reflector-controller,image-automation-controller \
  --url=ssh://git@github.com/piny940/infra \
  --branch=main \
  --private-key-file=/home/$(whoami)/.ssh/ed25519 \
  --path=kubernetes/_flux/${K8S_ENV}

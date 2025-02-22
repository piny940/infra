# piny940's infra

[![CI](https://github.com/piny940/infra/actions/workflows/ci.yaml/badge.svg)](https://github.com/piny940/infra/actions/workflows/ci.yaml)
[![Production Deploy](https://github.com/piny940/infra/actions/workflows/prd-deploy.yaml/badge.svg)](https://github.com/piny940/infra/actions/workflows/prd-deploy.yaml)
[![Staging Deploy](https://github.com/piny940/infra/actions/workflows/stg-deploy.yaml/badge.svg)](https://github.com/piny940/infra/actions/workflows/stg-deploy.yaml)

![Prd Nodes Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fk8s-status-badge.piny940.com%2Fnodes)
![Prd Pods Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fk8s-status-badge.piny940.com%2Fpods)

![Stg Nodes Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fstg-k8s-status-badge.piny940.com%2Fnodes)
![Stg Pods Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fstg-k8s-status-badge.piny940.com%2Fpods)

## 概要

ansible で自宅サーバーの構成管理: [ansible/README.md](ansible/README.md)

k8s の構築手順: [kubernetes/README.md](kubernetes/README.md)

GCP リソースの terraform 管理：[gcp/](gcp)

AWS リソースの terraform 管理：[aws/](aws)

## 物理構成

| マシン名 | IP | OS | CPU | Memory | Disk |
| --- | --- | --- | --- | --- | --- |
| peach | 192.168.151.158 | Ubuntu 24.04 | 6コア12スレッド | 16GB | 1TB |
| cherry | 192.168.151.104 | Ubuntu 24.04 | 6コア12スレッド | 16GB | 512GB |
| olive | 192.168.151.180 | Ubuntu 24.04 | 4コア4スレッド | 8GB | 512GB |

## VM 構成

| ホスト名 | IP | OS | CPU | Memory | Disk |
| --- | --- | --- | --- | --- | --- |
| peach | 192.168.151.158 | Ubuntu 24.04 | 6コア12スレッド | 16GB | 1TB |
| cherry | 192.168.151.104 | Ubuntu 24.04 | 6コア12スレッド | 16GB | 512GB |
| olive | 192.168.151.180 | Ubuntu 24.04 | 4コア4スレッド | 8GB | 512GB |

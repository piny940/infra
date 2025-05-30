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

## 構成

<img src="docs/machines.svg" alt="machines" style="max-width:800px" />

### 物理マシン

| マシン名 | IP              | OS           | CPU                | Memory | Disk  |
| -------- | --------------- | ------------ | ------------------ | ------ | ----- |
| peach    | 192.168.151.158 | Ubuntu 24.04 | 6 コア 12 スレッド | 16GB   | 1TB   |
| cherry   | 192.168.151.104 | Ubuntu 24.04 | 6 コア 12 スレッド | 16GB   | 512GB |
| olive    | 192.168.151.180 | Ubuntu 24.04 | 4 コア 4 スレッド  | 8GB    | 512GB |
| kiwi     | 192.168.151.123 | Ubuntu 24.04 | 8 コア 12 スレッド | 32GB   | 1TB   |

### マシン役割

| ホスト名                 | 役割                   | 物理マシン | IP              | OS           | CPU     | Memory | Disk  |
| ------------------------ | ---------------------- | ---------- | --------------- | ------------ | ------- | ------ | ----- |
| pollux                   | HA Proxy               | kiwi       | 192.168.151.235 | Ubuntu 24.04 | 2 コア  | 2GB    | 64GB  |
| castor                   | HA Proxy               | peach      | 192.168.151.223 | Ubuntu 24.04 | 2 コア  | 2GB    | 64GB  |
| vega                     | Controller(prd)        | cherry     | 192.168.151.229 | Ubuntu 24.04 | 2 コア  | 4GB    | 64GB  |
| altair                   | Controller(prd)        | peach      | 192.168.151.224 | Ubuntu 24.04 | 2 コア  | 4GB    | 64GB  |
| deneb                    | Controller(prd)        | kiwi       | 192.168.151.233 | Ubuntu 24.04 | 2 コア  | 4GB    | 64GB  |
| rigel                    | Worker(prd)            | cherry     | 192.168.151.228 | Ubuntu 24.04 | 10 コア | 8GB    | 256GB |
| betelgeuse               | Worker(prd)            | peach      | 192.168.151.225 | Ubuntu 24.04 | 6 コア  | 8GB    | 660GB |
| bellatrix                | Worker(prd)            | kiwi       | 192.168.151.234 | Ubuntu 24.04 | 6 コア  | 8GB    | 128GB |
| serius                   | k0sctl                 | peach      | 192.168.151.226 | Ubuntu 24.04 | 1 コア  | 2GB    | 64GB  |
| procyon                  | Controller+Worker(stg) | kiwi       | 192.168.151.236 | Ubuntu 24.04 | 6 コア  | 12GB   | 512GB |
| olive                    | Worker(prd)            | olive      | 192.168.151.158 | Ubuntu 24.04 | 4 コア  | 8GB    | 512GB |
| keepalive(pollux+castor) | Controller(prd)        | kiwi+peach | 192.168.151.11  |              |         |        |       |
| crt                      | vyos                   | kiwi       | 192.168.151.104 | vyos1.5      | 2 コア  | 512MB  | 2GB   |
| br01                     | vyos                   | kiwi       | 192.168.151.102 | vyos1.5      | 2 コア  | 512MB  | 2GB   |
| br02                     | vyos                   | kiwi       | 192.168.151.103 | vyos1.5      | 2 コア  | 512MB  | 2GB   |

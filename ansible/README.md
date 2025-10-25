# Ansible

## Requirement

- [Taskfile](https://taskfile.dev) installed

## Install

- `task install`

## Run Ansible

- staging: `PLAYBOOK=... PROJECT=... task run:stg`
- production: `PLAYBOOK=... PROJECT=... task run:prd`

By default, `PROJECT` is `home-cluster`, and `PLAYBOOK` is `cluster.yaml`. You can run `task run:stg` or `task run:prd`.

To specify tags: `task run:stg -- -t {tagname}`

## Vault

```bash
PROJECT=... task vault
```

作成した vars ファイルへのパスは`vars_files`に記述する。

## Lint

```bash
task lint
```

## Show Facts

```bash
PLAYBOOK=facts.yaml task run:stg | less
```

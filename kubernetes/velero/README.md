## インストール

[kubernetes/README.md](kubernetes/README.md) を参照してください。

## バックアップ

```bash
velero backup create --from-schedule velero-backup-daily
```

## Helm Upgrade

```bash
env=staging
helm upgrade velero vmware-tanzu/velero --namespace velero --values velero/base/values.yaml --values velero/staging/values.yaml --version 6.7.0
```

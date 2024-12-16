## インストール

[kubernetes/README.md](kubernetes/README.md) を参照してください。

## バックアップ

```bash
velero backup create --from-schedule velero-backup-daily
```

## Helm Upgrade

```bash
env=staging
helm repo update vmware-tanzu
helm upgrade velero vmware-tanzu/velero --namespace velero --values velero/base/values.yaml --values velero/$env/values.yaml --version 8.1.0
```

# Terraform

GCP を IaC で構築するコード。

## 開発

- PR を作成：`terraform plan` で変更点を確認
- `Terraform Apply` の CI を PR のブランチに対して実行：`staging` 環境に反映
- main ブランチにマージ：`production`, `staging` 両方に反映

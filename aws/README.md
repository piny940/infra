# AWS

AWS の構成を terraform で管理する。

## ディレクトリ構成について

GCP のように `staging` と `production` の共通要素を `module` に括りだすことも考えた。
しかし、AWS では GCP のように staging と production で project を分けることができず、 `staging` 環境のリソースにはすべて `stg-` prefix をつける必要が生じる。
そうなると、 `module` の実装が複雑になってしまうため、AWS では `staging` と `production` で（ほぼ同じコードになるけれど）別々のディレクトリに分けて管理することにした。

参考：<https://engineering.mercari.com/blog/entry/20220121-securing-terraform-monorepo-ci/>

staging と production は別々に apply したいため、[AWS 公式](https://docs.aws.amazon.com/ja_jp/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html)の形は難しそう？

## 初回 backend の設定メモ

- backend を指定していない状態で `terraform init` （ローカルに `.tfstate` が作られる）
- s3 を記述して `terraform apply`
- backend を指定
- `terraform init -migrate-state`

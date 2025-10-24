# k8s クラスタの立て方

## 事前準備

`ansible/` で環境構築を済ませておく

## コードが最新の状態になっていることを確認

```bash
git pull
```

## k0sctl を実行

```bash
env=staging
if [ "$env" = "staging" ]; then
  ext=stg
else
  ext=prd
fi
k0sctl apply --config cluster/k0sctl."$ext".yaml
```

## config を作成

```bash
env=staging
if [ "$env" = "staging" ]; then
  ext=stg
else
  ext=prd
fi
mkdir -p ~/.kube
k0sctl kubeconfig --config cluster/k0sctl."$ext".yaml > ~/.kube/config
```

## namespace を作成

```bash
kubectl apply -k namespaces
```

## longhorn をインストール

```bash
export env=staging
sh apps/longhorn/install.sh
```

## Workload Identity 連携を設定

`cluster-jwks.json` を作成

```bash
kubectl get --raw /openid/v1/jwks > $HOME/cluster-jwks.json
```

ローカルにダウンロード（ローカルで実行）

```bash
env=staging
hostname=procyon
scp "$hostname":cluster-jwks.json "$env"-cluster-jwks.json
```

`gcp/{env}/cluster-jwks.json` を置き換える

```bash
env=staging
dir=Documents/github/infra/gcp/staging/cluster-jwks.json
cp "$env"-cluster-jwks.json "$dir"
```

## バックアップを復元

参考: https://velero.io/docs/v1.13/restore-reference/

鍵をアップロード（ローカルで実行）（初回のみ）

```bash
env=staging
hostname=procyon
scp ~/$env-velero-credentials.json "$hostname":velero-credentials.json
scp ~/$env-velero-backblaze-credential.txt "$hostname":velero-backblaze-credential.txt
```

鍵を作成

```bash
kubectl create secret generic google-credentials -n velero --from-file=gcp=$HOME/velero-credentials.json
kubectl create secret generic backblaze-credential -n velero --from-file=backblaze=$HOME/velero-backblaze-credential.txt
```

Velero をインストール

```bash
export env=staging
sh apps/velero/install.sh
```

次のコマンドで、バックアップが sync されているのを確認する。

```bash
velero get backup
```

バックアップを復元する。

```bash
velero restore create --include-cluster-resources --exclude-namespaces velero,flux-system,kube-system,longhorn-system,metallb-system,ingress-nginx --from-backup {backup-name}
```

## Vault のセットアップ

vault の key をアップロード（ローカルで実行）（初回のみ）

```bash
env=staging
hostname=procyon
scp ~/$env-cluster-keys.json "$hostname":cluster-keys.json
```

[apps/vault/README.md](apps/vault/README.md)に従う

## FluxCD のセットアップ

バックアップからの復元が終わるまで待って実行

秘密鍵を作成。(初回のみ)  
作成した鍵の公開鍵は GitHub の Deploy Keys に登録する。(<https://github.com/piny940/infra/settings/keys>)

```bash
ssh-keygen -t ed25519 -f ~/flux-ed25519.key
cat ~/flux-ed25519.key.pub
```

以下、毎回実行

```bash
env=staging
kubectl -n flux-system delete secret flux-system
flux bootstrap git \
  --components-extra=image-reflector-controller,image-automation-controller \
  --url=ssh://git@github.com/piny940/infra \
  --branch=main \
  --private-key-file=/home/$(whoami)/flux-ed25519.key \
  --path=kubernetes/_flux/$env
```

## 補足

バックアップから復元しない場合
https://github.com/kubernetes-csi/external-snapshotter/tree/master?tab=readme-ov-file
を入れる必要がある

## チェックポイント

- 必須ポートは開いてる？(ファイアウォール)
- swap は無効化されている？
- containerd の設定は正しい？
- longhorn のために iscsid 入れた？
- コマンドを実行してるディレクトリ(`pwd`)は正しい？

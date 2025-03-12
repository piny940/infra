## flux の kustomization 生成

```bash
bash scripts/flux-kustomize.sh
```

## 開発

- GitHub に push すると staging 環境に更新が走る
- Merge すると staging・production の両方に更新が走る

## k8s クラスタの立て方
<!-- 
### 事前準備

- containerd が入っていない場合はインストールする
  - [docker](https://docs.docker.com/engine/install/) をインストールしたら勝手についてくる
- [必要なポート](https://kubernetes.io/ja/docs/reference/networking/ports-and-protocols/)が開いているか確認する
  - `nc 127.0.0.1 6443 -v`やらで確認できる(?)

### swap の無効化(再起動ごとに必須)

```bash
sudo swapoff -a
```

swap が無効化されたことを確認する。

```
$ free
               total        used        free      shared  buff/cache   available
Mem:        15754048     5720296      500028       40940     9533724     9621676
Swap:              0           0           0
```

再起動しても無効にするには`/etc/fstab`の swap っぽい行をコメントアウトする。

### パッケージのインストール(初回のみ)

参考: https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

必要なパッケージをインストール

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

公開署名キーをダウンロード・レポジトリを追加

```bash
KUBE_VERSION=1.30
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

パッケージをインストール

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### containerd の設定(初回のみ)

参考: https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/#containerd

まずはデフォルトの設定を適用する。

```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

`/etc/containerd/config.toml`を編集して`SystemdCgroup = true` に変更する。

```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

disabled_plugins リストに cri が含まれていないことを確認する。
執筆時は以下のようになっていた。

```
$ sudo cat /etc/containerd/config.toml | grep disabled_plugins
disabled_plugins = []
```

変更を適用する。

```bash
sudo systemctl restart containerd
```

### flannel のための設定(初回のみ)

```bash
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee -a /etc/sysctl.conf
```

### longhorn のための設定(初回のみ)

```bash
sudo apt -y install open-iscsi nfs-common
sudo systemctl start iscsid
sudo systemctl enable iscsid
```

multipathd が干渉しないようにする（参考: <https://longhorn.io/kb/troubleshooting-volume-with-multipath/>）

```bash
sudo vi /etc/multipath.conf
```

以下を追記する。

```conf
blacklist {
    devnode "^sd[a-z0-9]+"
}
```

```bash
sudo systemctl restart multipathd.service
```

### flux をインストール(初回のみ)

参考: https://fluxcd.io/flux/installation/

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
. <(flux completion bash)
```

### velero CLI をインストール(初回のみ)

参考: https://velero.io/docs/v1.13/basic-install/

- [latest release](https://github.com/vmware-tanzu/velero/releases/latest)から tar をダウンロード
- 展開してバイナリを移動
- tab 補完を追加

```bash
VELERO_VERSION=1.15.0
wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
sudo mv velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/
echo 'source <(velero completion bash)' >>~/.bashrc
```

### Helm をインストール(初回のみ)

参考: https://helm.sh/ja/docs/intro/install/

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

### Vault CLI をインストール(初回のみ)

参考: https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install

```bash
sudo apt update && sudo apt install gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault
```

### k9s をインストール(初回のみ)

```bash
wget https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_linux_amd64.deb \
  && sudo apt install ./k9s_linux_amd64.deb \
  && rm k9s_linux_amd64.deb
``` -->

<!-- ### kubeadm init

CNI の設定やらの残骸を削除

```bash
sudo rm /etc/cni/net.d/*
```

コードが最新になっていることを確認

```bash
cd $HOME/infra/kubernetes
git pull
```

```bash
sudo kubeadm init --config kubeadm-config.yaml
```

表示されたコマンドを実行する。

```bash
sudo rm -r $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

必要に応じてノードを追加する。

```bash
kubeadm join ...
```

### taint を削除

```bash
kubectl taint nodes {node-name} node-role.kubernetes.io/control-plane:NoSchedule-
``` -->

### k0s を実行

```bash
k0sctl apply --config k0sctl.yaml
```

### namespace を作成

```bash
kubectl apply -k namespaces
```

### Workload Identity 連携を設定

`cluster-jwks.json` を作成

```bash
kubectl get --raw /openid/v1/jwks > $HOME/cluster-jwks.json
```

ローカルにダウンロード（ローカルで実行）

```bash
env=staging
hostname=cherry
scp "$hostname":cluster-jwks.json "$env"-cluster-jwks.json
```

`gcp/{env}/cluster-jwks.json` を置き換える

### バックアップを復元

参考: https://velero.io/docs/v1.13/restore-reference/

鍵をアップロード（ローカルで実行）（初回のみ）

```bash
env=staging
hostname=cherry
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
env=staging
sh velero/$env/install.sh
```

次のコマンドで、バックアップが sync されているのを確認する。

```bash
velero get backup
```

バックアップを復元する。

まずは longhorn

```bash
velero restore create --include-cluster-resources --include-namespaces longhorn-system --from-backup {backup-name}
```

完了したらそれ以外のリソースを復元

```bash
velero restore create --include-cluster-resources --exclude-namespaces velero,flux-system,kube-system,longhorn-system --from-backup {backup-name}
```

### Vault のセットアップ

vault の key をアップロード（ローカルで実行）（初回のみ）

```bash
env=staging
hostname=cherry
scp ~/$env-cluster-keys.json "$hostname":cluster-keys.json
```

[apps/vault/README.md](apps/vault/README.md)に従う

### FluxCD のセットアップ

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

Staging 環境の場合は git repository を作成する

```bash
kubectl apply -f _flux/staging/flux-system/git-repository.yaml
```

### 補足

バックアップから復元しない場合
https://github.com/kubernetes-csi/external-snapshotter/tree/master?tab=readme-ov-file
を入れる必要がある

## ノードの追加方法

マスターノードでトークン・証明書を作成

```bash
kubeadm token create
```

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
| openssl rsa -pubin -outform der 2>/dev/null \
| openssl dgst -sha256 -hex | sed 's/^.* //'
```

ワーカーノードでトークンを使って join

```bash
sudo kubeadm join {master-ip}:6443 --token {token} --discovery-token-ca-cert-hash sha256:{hash}
```

## チェックポイント

- 必須ポートは開いてる？(ファイアウォール)
- swap は無効化されている？
- containerd の設定は正しい？
- longhorn のために iscsid 入れた？
- `.env` は正しい？
- コマンドを実行してるディレクトリ(`pwd`)は正しい？

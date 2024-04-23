# piny940's infra

## k8s クラスタの立て方

### 0. 事前準備

- containerd が入っていない場合はインストールする
  - docker をインストールしたら勝手についてくる
- [必要なポート](https://kubernetes.io/ja/docs/reference/networking/ports-and-protocols/)が開いているか確認する
  - `nc 127.0.0.1 6443 -v`やらで確認できる(?)

### 1. swap の無効化(初回のみ)

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

### 2. パッケージのインストール(初回のみ)

参考: https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

```bash
sudo apt-get update
# apt-transport-httpsはダミーパッケージの可能性があります。その場合、そのパッケージはスキップできます
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# `/etc/apt/keyrings`フォルダーが存在しない場合は、curlコマンドの前に作成する必要があります。下記の備考を参照してください。
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# これにより、/etc/apt/sources.list.d/kubernetes.listにある既存の設定が上書きされます
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 3. containerd の設定(初回のみ)

参考: https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/#containerd

まずはデフォルトの設定を適用する。

```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

`SystemdCgroup = true` に変更する。

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

<p style="font-size:40px">
以下のコマンドは<code>kubernetes/</code>ディレクトリで実行する。
</p>

### 4. kubeadm init

```bash
sudo kubeadm init --config kubeadm-config.yaml
```

表示されたコマンドを実行する。

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

必要に応じてノードを追加する。

```bash
kubeadm join ...
```

### 4. namespace を作成

```bash
kubectl apply -k namespaces
```

- `kubectl apply -k namespaces`
- `bash init_flux.sh`

```

```

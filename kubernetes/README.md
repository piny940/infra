## クラスタ立て方

- `sudo kubeadm init --config kubeadm-config.yaml`
- `bash init_cni.sh`
- ノードを追加(kubeadm join)
- `kubectl apply -k namespaces`
- `bash init_flux.sh`

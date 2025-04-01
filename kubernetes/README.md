# Kubernetes

## 開発

- GitHub に push すると staging 環境に更新が走る
- Merge すると staging・production の両方に更新が走る

## CI

```bash
bash scripts/cluster-tls.sh
bash scripts/flux-kustomize.sh
bash scripts/ytt.sh
bash scripts/kubeconform.sh
```

## クラスタ起動手順

- [INIT.md](INIT.md)

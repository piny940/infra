# Vault

参考: https://qiita.com/piny940/items/66214e8f7c8af18ba014

## CLI をインストール(初回のみ)

[kubernetes/README.md](../..//README.md) を参照。

## Vault サーバーの起動

`init.sh`のコマンドを**1 つずつ**実行していく

## WebUI にログイン

`jq -r ".root_token" cluster-keys.json`でトークンを取得し、ログインする。

## Admin ユーザーを作成

root アカウントだと危険なので、admin ユーザーを作成する。

`Policies` > 'Create ACL Policy' で以下のポリシーを作成する。

```
path "k8s/*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}
```

`k8s/`以下のリソースに対して、全ての操作が可能なポリシーになっている。

`Access` > `Enable new method`で`Userpass`を有効にする。
`Path`は適当で OK

ユーザーを作成する。

- `Generated Token's Policies`は先程作成したものを選択する。
- `Generated Token's Initial TTL`は`86400`(24h)にする。

これで、admin ユーザーが作成される。

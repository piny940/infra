# Ansible

## Install Ansible

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

## Run Ansible

```bash
env=staging
ansible-playbook -i inventories/"$env" cluster.yaml -e env="$env"
```

## Vault

```bash
ansible-vault edit vars/"$filename".yaml
```

作成した vars ファイルへのパスは`vars_files`に記述する。

## Lint

```bash
ansible-lint --fix
```

## Show Facts

```bash
env=staging
ansible-playbook -i inventories/"$env" facts.yaml | less
```

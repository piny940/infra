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
ansible-playbook -i "$env" cluster.yaml --vault-pass-file passwd.txt
```

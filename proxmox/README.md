# Proxmox

自宅サーバーの Proxmox リソースを terraform で管理

- `terraform plan`
- `terraform apply`

## vyOS

構築後，IP アドレスを割り当てる

```sh
configure
set interfaces ethernet eth0 address 192.168.151.xx/23
```

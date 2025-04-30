terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.77.0"
    }
  }
}
provider "proxmox" {
  endpoint = "https://192.168.151.123:8006/"
  insecure = true

  username = "root@pam"
  password = var.proxmox_passwd

  ssh {
    agent = true
  }
}

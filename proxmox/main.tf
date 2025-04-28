data "http" "authorized-keys" {
  url                = "https://raw.githubusercontent.com/piny940/dotfiles/refs/heads/main/.ssh/authorized_keys"
  request_timeout_ms = 3000
}
resource "proxmox_virtual_environment_download_file" "kiwi_ubuntu_noble_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "kiwi"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.img"
}
resource "proxmox_virtual_environment_download_file" "cherry_ubuntu_noble_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "cherry"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.img"
}
resource "proxmox_virtual_environment_download_file" "peach_ubuntu_noble_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "peach"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.img"
}
resource "proxmox_virtual_environment_download_file" "kiwi_vyos_rolling_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "kiwi"
  url          = "https://github.com/vyos/vyos-nightly-build/releases/download/1.5-rolling-202503030030/vyos-1.5-rolling-202503030030-generic-amd64.iso"
  file_name    = "vyos-1.5-rolling-202503030030-generic-amd64.iso"
}
resource "proxmox_virtual_environment_vm" "procyon" {
  name            = "procyon"
  vm_id           = 107
  node_name       = "kiwi"
  on_boot         = true
  scsi_hardware   = "virtio-scsi-single"
  started         = true
  stop_on_destroy = true
  cpu {
    cores = 6
    type  = "x86-64-v2-AES"
  }
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.kiwi_ubuntu_noble_cloud_image.id
    iothread     = true
    interface    = "scsi0"
    size         = 512
  }
  memory {
    dedicated = 12000
  }
  network_device {
    bridge = "vmbr0"
  }
  initialization {
    dns {
      servers = ["192.168.150.1"]
    }
    ip_config {
      ipv4 {
        address = "192.168.151.236/23"
        gateway = "192.168.150.1"
      }
    }
    user_account {
      username = var.username
      keys     = split("\n", trimspace(data.http.authorized-keys.response_body))
    }
  }
}
resource "proxmox_virtual_environment_network_linux_bridge" "kiwi_vmbr11" {
  node_name = "kiwi"
  name      = "vmbr11"
}
resource "proxmox_virtual_environment_vm" "brt01" {
  name            = "brt01"
  node_name       = "kiwi"
  on_boot         = true
  scsi_hardware   = "virtio-scsi-single"
  started         = true
  stop_on_destroy = true
  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }
  disk {
    datastore_id = "local-lvm"
    iothread     = true
    interface    = "scsi0"
    size         = 2
  }
  cdrom {
    file_id   = proxmox_virtual_environment_download_file.kiwi_vyos_rolling_cloud_image.id
    interface = "ide3"
  }
  memory {
    dedicated = 512
  }
  network_device {
    bridge = local.default_bridge
  }
  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.kiwi_vmbr11.name
  }
  initialization {
    dns {
      servers = ["192.168.150.1"]
    }
    ip_config {
      ipv4 {
        address = "192.168.151.102/23"
        gateway = "192.168.150.1"
      }
    }
    user_account {
      username = var.username
      keys     = split("\n", trimspace(data.http.authorized-keys.response_body))
    }
  }
}

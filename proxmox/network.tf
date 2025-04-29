resource "proxmox_virtual_environment_network_linux_bridge" "kiwi_vmbr11" {
  node_name = "kiwi"
  name      = "vmbr11"
}
resource "proxmox_virtual_environment_network_linux_bridge" "kiwi_vmbr12" {
  node_name = "kiwi"
  name      = "vmbr12"
}
resource "proxmox_virtual_environment_vm" "brt01" {
  name            = "brt01"
  node_name       = "kiwi"
  on_boot         = true
  scsi_hardware   = "virtio-scsi-single"
  started         = true
  stop_on_destroy = true
  cpu {
    cores = 2
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

resource "proxmox_virtual_environment_vm" "brt02" {
  name            = "brt02"
  node_name       = "kiwi"
  on_boot         = true
  scsi_hardware   = "virtio-scsi-single"
  started         = true
  stop_on_destroy = true
  cpu {
    cores = 2
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
    bridge = proxmox_virtual_environment_network_linux_bridge.kiwi_vmbr12.name
  }
  initialization {
    ip_config {
      ipv4 {
        address = "192.168.151.103/23"
        gateway = "192.168.150.1"
      }
    }
    user_account {
      username = var.username
      keys     = split("\n", trimspace(data.http.authorized-keys.response_body))
    }
  }
}

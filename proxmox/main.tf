resource "proxmox_virtual_environment_vm" "procyon" {
  acpi                    = true
  bios                    = "seabios"
  description             = null
  id                      = "107"
  ipv4_addresses          = []
  ipv6_addresses          = []
  keyboard_layout         = null
  kvm_arguments           = null
  mac_addresses           = []
  machine                 = null
  name                    = "procyon"
  network_interface_names = []
  node_name               = "kiwi"
  protection              = false
  scsi_hardware           = "virtio-scsi-single"
  started                 = true
  tablet_device           = true
  tags                    = []
  template                = false
  vm_id                   = 107

  cpu {
    affinity     = null
    architecture = null
    cores        = 6
    flags        = []
    hotplugged   = 0
    limit        = 0
    numa         = false
    sockets      = 1
    type         = "x86-64-v2-AES"
    units        = 1024
  }

  disk {
    aio               = "io_uring"
    backup            = true
    cache             = "none"
    datastore_id      = "local"
    discard           = "ignore"
    file_format       = "iso"
    file_id           = null
    interface         = "ide2"
    iothread          = false
    path_in_datastore = "iso/ubuntu-24.04.2-live-server-amd64.iso"
    replicate         = true
    serial            = null
    size              = 2
    ssd               = false
  }
  disk {
    aio               = "io_uring"
    backup            = true
    cache             = "none"
    datastore_id      = "local-lvm"
    discard           = "ignore"
    file_format       = "raw"
    file_id           = null
    interface         = "scsi0"
    iothread          = true
    path_in_datastore = "vm-107-disk-0"
    replicate         = true
    serial            = null
    size              = 512
    ssd               = false
  }

  memory {
    dedicated      = 12000
    floating       = 0
    hugepages      = null
    keep_hugepages = false
    shared         = 0
  }

  network_device {
    bridge       = "vmbr0"
    disconnected = false
    enabled      = true
    firewall     = true
    mac_address  = "BC:24:11:A6:4B:A9"
    model        = "virtio"
    mtu          = 0
    queues       = 0
    rate_limit   = 0
    trunks       = null
    vlan_id      = 0
  }

  operating_system {
    type = "l26"
  }
}

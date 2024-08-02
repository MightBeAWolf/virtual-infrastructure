# Debian 12 Template
# ---

variable "proxmox_cluster_host" {
    # Set from the ./run.sh
    type = string
}

variable "proxmox_cluster_node" {
    # Set from the ./run.sh
    type = string
}

variable "id" {
    # Set from the ./run.sh
    type = string
}

variable "preseed_file" {
  type    = string
  default = "template.preseed"
}

variable "name" {
  type    = string
  default = "debian-12-base" 
}

variable "vlan" {
    type = string
    default = ""
}

variable "pool" {
    type = string
    default = ""
}

variable "domain" {
  type    = string
  default = ""
}

variable "guest_username" {
    # Set from the ./run.sh
    type = string
    default = "admin"
}

variable "guest_password" {
    # Set from the ./run.sh
    type = string
    sensitive = true
}

variable "desc" {
  type = string 
}

variable "http_interface" {
    # Specifies the interface to use for the web server
    type = string
}

variable "tags" {
  type = string
}

variable "disk" {
  type = object({
    storage = string
    size    = string
  })
  default = {
    storage = "local-lvm"
    size    = "20G"
  }
}

packer {
  required_plugins {
    name = {
      version = "~> 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}


# Resource Definiation for the VM Template
source "proxmox-iso" "debian-12-base" {
    # Proxmox host settings
    proxmox_url = "https://${var.proxmox_cluster_host}/api2/json"
 
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true

    http_interface = "${var.http_interface}"
    
    # VM General Settings
    node = "${var.proxmox_cluster_node}"
    pool = "${var.pool}"
    vm_id = "${var.id}"
    vm_name = "${var.name}"
    template_description = "${var.desc}"
    tags = "${var.tags}"

    # VM OS Settings
    # (Option 1) Local ISO File
    # iso_file = "local:iso/ubuntu-20.04.2-live-server-amd64.iso"
    # - or -
    # (Option 2) Download ISO
    iso_url = "https://cdimage.debian.org/debian-cd/12.6.0/amd64/iso-cd/debian-12.6.0-amd64-netinst.iso"
    iso_checksum = "sha256:ade3a4acc465f59ca2496344aab72455945f3277a52afc5a2cae88cdc370fa12"
    iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size    = var.disk.size
        storage_pool = var.disk.storage
        type = "virtio"
        format = "raw"
    }

    # VM CPU Settings
    cores = "1"
    
    # VM Memory Settings
    memory = "2048" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "true"
        vlan_tag = "${var.vlan}"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    boot_command = [
        "<wait><wait><wait><esc><wait><wait><wait>",
        "/install.amd/vmlinuz ",
        "initrd=/install.amd/initrd.gz ",
        "auto=true ",
        "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed_file} ",
        "hostname=${var.name} ",
        "domain=${var.domain} ",
        "interface=auto ",
        "vga=788 noprompt quiet --<enter>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_content = { "/${var.preseed_file}" = templatefile(var.preseed_file, { var = var }) }
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    http_port_min = 49152
    http_port_max = 49154

    ssh_username = "${var.guest_username}"
    # (Option 1) Add your Password here
    ssh_password = "${var.guest_password}"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    # ssh_private_key_file = "~/.ssh/id_ed25519"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "debian-12-base"
    sources = ["source.proxmox-iso.debian-12-base"]

    provisioner "file" {
        sources = [
            "files/20auto-upgrades",
            "files/50unattended-upgrades",
            "files/99-pve.cfg",
            "files/cloud.cfg"
        ]
        destination = "/tmp/"
    }

    provisioner "shell" {
        script = "files/provision.sh"
    }

}


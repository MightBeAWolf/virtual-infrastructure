# Redhat 8 Template
# ---

variable "proxmox_cluster_api_uri" {
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

variable "kickstart_file" {
  type    = string
  default = "files/kickstart.ks"
}

variable "name" {
  type    = string
  default = "redhat-8-base" 
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

variable "openldap_sssd_dn" {
    # Set from the ./run.sh
    type = string
    sensitive = true
}

variable "openldap_sssd_dn_password" {
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
source "proxmox-iso" "redhat-8-base" {
    # Proxmox host settings
    proxmox_url = var.proxmox_cluster_api_uri
 
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
    iso_file = "wolftrack-nas:iso/rhel-8.10-x86_64-boot.iso"
    iso_checksum = "none"
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
    cores = "4"
    
    # VM Memory Settings
    memory = "4096" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "true"
        vlan_tag = "${var.vlan}"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = var.disk.storage

    boot_command = [
        "<wait><wait><wait><esc><wait><wait><wait>",
        "vmlinuz ",
        "initrd=initrd.img ",
        "ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.kickstart_file} ",
        "<enter>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_content = { "/${var.kickstart_file}" = templatefile(var.kickstart_file, { var = var }) }
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
    # NOTE: Installing a template to a shared storage (hosted on the network)
    # can take a long time. Yet this is required so that the template can be
    # used on all nodes sharing that storage
    ssh_timeout = "180m"
}

# Build Definition to create the VM Template
build {

    name = "redhat-8-base"
    sources = ["source.proxmox-iso.redhat-8-base"]

    provisioner "file" {
        source = "files/config.d"
        destination = "/tmp/"
    }

    provisioner "file" {
        content = templatefile("files/templates/sssd.conf", {var=var})
        destination = "/tmp/config.d/sssd.conf"
    }

    provisioner "file" {
        content = templatefile("files/templates/cloud.cfg", {var=var})
        destination = "/tmp/config.d/cloud.cfg"
    }

    provisioner "file" {
        source = "files/provision.d"
        destination = "/tmp/provision.d"
    }

    provisioner "shell" {
        script = "files/provision.sh"
    }

    provisioner "shell" {
        inline = ["rm -rf /tmp/config.d"]
    }

}


variable "ssh_pub_key" {
  description = "The public ssh key used to access the nodes"
  type        = string
  sensitive   = true
}

variable "node_user" {
  description = "The user created in the nodes"
  type        = string
}

variable "node_user_password" {
  description = "The password for the node user"
  type        = string
  sensitive   = true
}


variable "pm_api_uri" {
  description = "The Proxmox API URI."
  type        = string
}

variable "pm_api_token_id" {
  description = "The Proxmox API token created for a specific user."
  type        = string
}

variable "pm_api_token_secret" {
  description = "The password for the Proxmox API user"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Disable TLS verification for Proxmox API"
  type        = bool
  default     = true
}

variable "from_template" {
  description = "The name of the template to clone from"
  type        = string
  default     = true
}

variable "start_vm_on_boot" {
  description = "Whether to have the VM startup after the PVE node starts."
  type        = bool
  default     = false
}

variable "name" {
  type = string 
}

variable "id" {
  type = number 
}

variable "ipv4" {
  type = string 
}

variable "cidr" {
  type = string 
}

variable "gateway" {
  type = string 
}

variable "desc" {
  type = string 
}

variable "target_node" {
  type = string
}

variable "tags" {
  type = string
}

variable "pool" {
  type = string
}

variable "disk" {
  type = object({
    storage = string
    size    = string
    backup  = bool
  })
  default = {
    storage = "local-lvm"
    size    = "20G"
    backup  = true
  }
}

variable "network" {
  type = object({
    bridge = string
    model  = string
    tag = number
  })
  default = {
    bridge = "vmbr0"
    model  = "virtio"
    tag    = 40
  }
}

variable "compute" {
  description = "Resource settings for each VM"
  type = object({
    sockets  = number
    cores   = number
    memory  = number
  })
  default = {
    sockets = 1
    cores   = 1
    memory  = 512
  }
}


terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}


provider "proxmox" {
  pm_api_url          = var.pm_api_uri
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "guest_vms" {
  name  = "${var.name}"
  clone = "${var.from_template}"
  desc = "${var.desc}"
  target_node="${var.target_node}"
  tags="${var.tags}"
  qemu_os = "l26"
  agent = 1
  pool = "${var.pool}"

  onboot = "${var.start_vm_on_boot}"

  vmid = "${var.id}"
  sockets = var.compute.sockets
  cores = var.compute.cores
  memory = var.compute.memory

  disks {
    ide{
      ide0{
        cloudinit{
          storage = var.disk.storage
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = var.disk.size
          storage = var.disk.storage
          backup = var.disk.backup
        }
      }
    }
  }

  network {
    bridge = var.network.bridge
    model = var.network.model
  }

  # Specify cloud init settings
  os_type    = "cloud-init"
  ipconfig0  = "ip=${var.ipv4}${var.cidr},gw=${var.gateway}"
  nameserver = "${var.gateway}"
  ciuser = var.node_user
  cipassword = var.node_user_password
  sshkeys = var.ssh_pub_key
}


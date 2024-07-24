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


variable "vm_resource_settings" {
  description = "Resource settings for each VM"
  type = object({
    cores   = number
    memory  = number
    disk    = object({
      storage = string
      size    = number
    })
    network = object({
      bridge = string
      model  = string
      tag = number
    })
  })
  default = {
    cores   = 2
    memory  = 2048
    disk    = {
      storage = "local-lvm"
      size    = 20
    }
    network = {
      bridge = "vmbr0"
      model  = "virtio"
      tag    = 40
    }
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

  vmid = "${var.id}"
  cores = var.vm_resource_settings.cores
  memory = var.vm_resource_settings.memory

  disks {
    ide{
      ide0{
        cloudinit{
          storage = var.vm_resource_settings.disk.storage
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = var.vm_resource_settings.disk.size
          storage = var.vm_resource_settings.disk.storage
        }
      }
    }
  }

  network {
    bridge = var.vm_resource_settings.network.bridge
    model = var.vm_resource_settings.network.model
  }

  # Specify cloud init settings
  os_type    = "cloud-init"
  ipconfig0  = "ip=${var.ipv4}${var.cidr},gw=${var.gateway}"
  nameserver = "${var.gateway}"
  ciuser = var.node_user
  cipassword = var.node_user_password
  sshkeys = var.ssh_pub_key
}


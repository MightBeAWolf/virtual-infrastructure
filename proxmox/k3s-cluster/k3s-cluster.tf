variable "onepassword_vault" {
  description = "The 1Password vault storing the credentials"
  type        = string
  sensitive   = true
}

variable "onepassword_service_token" {
  description = "The credential token for the 1Password service account"
  type        = string
  sensitive   = true
}

variable "onepassword_cli_path" {
  description = "The path on the local system of the 1password 'op' binary"
  type        = string
}

variable "pm_api_url" {
  description = "The Proxmox API URL"
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

variable "node_count" {
  description = "The number of K3s nodes to create"
  type        = number
  default     = 3
}

variable "k3s_node_to_target_node_map" {
  description = "The map describing where each node should be created"
  type = map(string)
  default = {
    0 = "pve"
    1 = "pve"
    2 = "pve"
  }
}

variable "vm_template_name" {
  description = "The name of the VM template to clone for K3s nodes"
  type        = string
  default     = "debian-12-base"
}

variable "vm_resource_settings" {
  description = "Resource settings for each K3s node VM"
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
    }
  }
}


terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "1.4.3"
    }
  }
}

provider "onepassword" {
  service_account_token = var.onepassword_service_token
  op_cli_path           = var.onepassword_cli_path
}

data "onepassword_vault" "vault" {
  name=var.onepassword_vault
}


provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "k3s_node" {
  count = var.node_count
  name  = "k3s-node-${count.index}"
  clone = var.vm_template_name
  desc = "Kubernetes K3S on Debian 12 via '${var.vm_template_name}' template"
  target_node="${var.k3s_node_to_target_node_map[count.index]}"
  tags = "debian-12;k3s"
  qemu_os = "l26"
  agent = 1

  vmid = format("4%02v", count.index)
  cores = var.vm_resource_settings.cores
  memory = var.vm_resource_settings.memory

  disks {
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
  os_type = "cloud-init"
  ipconfig0 = format("ip=10.20.4.%g/24,gw=10.20.0.1", count.index + 1)
  nameserver = "10.20.0.1"
  # ciuser = ""
  # sshkeys = <<HEREDOC
  # ssh-eda25519 ................... .......
  # HEREDOC

  # provisioner "remote-exec" {
  #   // Commands to install K3s go here
  # }
}


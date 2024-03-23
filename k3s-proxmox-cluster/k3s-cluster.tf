variable "pm_api_url" {
  description = "The Proxmox API URL"
  type        = string
}

variable "pm_user" {
  description = "The Proxmox user for API access"
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
    storage = string
  })
  default = {
    cores   = 2
    memory  = 2048
    storage = "local-lvm:20G"
  }
}


terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_user             = var.pm_user
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
  pm_debug            = true
}

resource "proxmox_vm_qemu" "k3s_node" {
  count = var.node_count
  name  = "k3s-node-${count.index}"
  clone = var.vm_template_name
  cores = var.vm_resource_settings.cores
  memory = var.vm_resource_settings.memory
  disk = var.vm_resource_settings.storage
  // Include additional configurations as needed

  provisioner "remote-exec" {
    // Commands to install K3s go here
  }
}


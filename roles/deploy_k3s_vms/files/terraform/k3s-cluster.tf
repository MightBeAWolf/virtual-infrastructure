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

variable "guest_k3s_nodes" {
  description = "The map describing each node"
  type = map(object({id = number, ipv4 = string, gateway = string, target_host = string}))
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
      version = "3.0.1-rc3"
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
  pm_api_url          = var.pm_api_uri
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "k3s_node" {
  for_each = var.guest_k3s_nodes
  name  = "${each.key}"
  clone = var.vm_template_name
  desc = "Kubernetes K3S via '${var.vm_template_name}' template"
  target_node="${each.value.target_host}"
  tags = "k3s"
  qemu_os = "l26"
  agent = 1

  vmid = "${each.value.id}"
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
  ipconfig0  = "ip=${each.value.ipv4},gw=${each.value.gateway}"
  nameserver = "${each.value.gateway}"
  ciuser = var.node_user
  cipassword = var.node_user_password
  sshkeys = var.ssh_pub_key
}


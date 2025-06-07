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

variable "name" {
  type    = string
  default = "template-of-template" 
}

variable "source_template" {
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

source "proxmox-clone" "template-of-template" {
    # Proxmox host settings
    proxmox_url = var.proxmox_cluster_api_uri
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true

    # task_timeout (duration string | ex: "1h5m2s") - task_timeout (duration
    # string | ex: "10m") - The timeout for Promox API operations, e.g. clones.
    # Defaults to 1 minute.
    task_timeout = "30m"

    http_interface = "${var.http_interface}"
    
    # VM General Settings
    node = "${var.proxmox_cluster_node}"
    pool = "${var.pool}"
    vm_id = "${var.id}"
    vm_name = "${var.name}"
    template_description = "${var.desc}"
    tags = "${var.tags}"

    # Source VM template to clone from
    clone_vm = "${var.source_template}"

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

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
    cloud_init_storage_pool = var.disk.storage

    ssh_username = "${var.guest_username}"
    # (Option 1) Add your Password here
    # ssh_password = "${var.guest_password}"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    # ssh_private_key_file = "~/.ssh/id_ed25519"

    # Raise the timeout, when installation takes longer
    # NOTE: Installing a template to a shared storage (hosted on the network)
    # can take a long time. Yet this is required so that the template can be
    # used on all nodes sharing that storage
    ssh_timeout = "180m"
}


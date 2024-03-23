# Virtualized Infrastructure


## Workstation Requirements

### 1Password App & CLI

### Packer by Hashicorp - [Link](https://www.packer.io/)

### Terraform by Hashicorp - [Link](https://developer.hashicorp.com/terraform/install)
 - https://github.com/Telmate/terraform-provider-proxmox

#### Enable 1Password Terraform plugin
```bash
op plugin init terraform
```

## Virtualization Targets
 - Proxmox VE 8 cluster consisting of atleast 1 node


 ## Steps to deploy from scratch
 1. Manually setup proxmox cluster
 2. Deploy Proxmox templates in [packer-vm-templates](./packer-vm-templates)
 3. Deploy Kubernetes cluster in [k3s-proxmox-cluster](./k3s-proxmox-cluster)

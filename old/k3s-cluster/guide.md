

## Terraform API Access Proxmox

A Terraform provider is responsible for understanding API interactions and exposing resources. The Proxmox provider uses
the Proxmox API. This provider exposes two resources: [proxmox_vm_qemu](resources/vm_qemu.md)
and [proxmox_lxc](resources/lxc.md).

### Creating the Proxmox user and role for terraform

The particular privileges required may change but here is a suitable starting point rather than using cluster-wide
Administrator rights

Log into the Proxmox cluster or host using ssh (or mimic these in the GUI) then:

- Create a new role for the future terraform user.
- Create the user "terraform-prov@pve"
- Add the TERRAFORM-PROV role to the terraform-prov user

```bash
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
pveum user add terraform-prov@pve --password <password>
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

The provider also supports using an API key rather than a password, see below for details.

After the role is in use, if there is a need to modify the privileges, simply issue the command showed, adding or
removing privileges as needed.


Proxmox > 8:
```bash
pveum role modify TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
```
Proxmox < 8:
```bash
pveum role modify TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"
```
For more information on existing roles and privileges in Proxmox, refer to the vendor docs
on [PVE User Management](https://pve.proxmox.com/wiki/User_Management)

### Creating the connection via username and password

When connecting to the Proxmox API, the provider has to know at least three parameters: the URL, username and password.
One can supply fields using the provider syntax in Terraform. It is recommended to pass secrets through environment
variables.

```bash
export PM_USER="terraform-prov@pve"
export PM_PASS="password"
```

Note: these values can also be set in main.tf but users are encouraged to explore Vault as a way to remove secrets from
their HCL.

```hcl
provider "proxmox" {
  pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
}
```

### Creating the connection via username and API token

```bash
export PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
export PM_API_TOKEN_SECRET="afcd8f45-acc1-4d0f-bb12-a70b0777ec11"
```

```hcl
provider "proxmox" {
  pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
}
```

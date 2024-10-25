<h1 align="center">Virtualized Infrastructure</h1>

<h4 align="center">A repository for implementing the infrastructure as code</h4>
<p align="center">
  <a href="#dependencies">Dependencies</a>
  <a href="#getting-started">Getting Started</a>
</p>

## Dependencies
### Workstation Requirements

- Both 1Password App & CLI - Must be installed
  - [CLI](https://developer.1password.com/docs/cli/)
  - [1Password App](https://support.1password.com/install-linux/)
- Packer by Hashicorp - Automatically Handled - [Link](https://www.packer.io/)
- Terraform by Hashicorp - Automatically Handled - [Link](https://developer.hashicorp.com/terraform/install)
  - Terraform Provider - Automatically Handled - [Link](https://github.com/Telmate/terraform-provider-proxmox)

### Virtualization Target Requirements
 - Proxmox VE 8 cluster consisting of atleast 1 node

## Getting Started

### Project Environment Setup
A helpful utility has been provided to setup the development environment. This
does the following:

- Sets up the git hooks
- Creates the virtual environment using the latest version of python on your machine.
  - Initializes the .venv
  - Updates pip
  - Installs the python dependencies

```bash
./run.sh setup
```

### Credentials
The following credentials need to be created and managed in 1password

> **Caution**
> Never store credentials/secrets in a plain text file, and never enable git
> to manage a credentials/secrets file even if encrypted! It is recommended for
> this project to use 1Password's secret reference format

#### Proxmox API Token
- Go to the Proxmox cluster web portal and login.
- Select the 'Datacenter' on the left side.
- Select 'Permissions -> API Tokens' and press 'Add'
- Specify the information:
  - User: yourself
  - Token ID: `ansible`
  - Privilege Seperation: NOT Checked
  - Expire: optional
- Copy the secret into a new 1Password API Credential
  - A `username` field should be present that includes the token id in the format <user>@pam!ansible
  - A `credential` field should be present storing the token secret
  - A `hostname` field should be present storing the FQDN `intel-nuc-13-01.local.wolfbox.dev:8006`
- Adjust the secrets.env to match your 1Password item information. set the following variabled
  - PROXMOX_API_TOKEN_ID should map to the `username` in the 1password item.
  - PROXMOX_API_SECRET should map to the `credential` in the 1password item.

The credentials can be tested with the command:
```bash
./run.sh credential-test
```

### Kicking off Ansible
Once the dependencies and credentials have been satisfied, you may execute
ansible using the command:

> **Note**
> We use the `./run.sh` instead of `ansible-playbook -K playbooks/main.yml` by
> itself as it handles most of credential initialization into the environment
> for us.

```
./run.sh ansible-playbook -K playbooks/main.yml
```



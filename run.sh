#!/bin/bash

export ANSIBLE_FORCE_COLOR=True

# Secrets
export ONEPASSWORD_VAULT="Local Cluster"
export PROXMOX_PACKER_API_TOKEN_ID="op://${ONEPASSWORD_VAULT:?}/Proxmox - Packer API Token/username"
export PROXMOX_PACKER_API_TOKEN_SECRET="op://${ONEPASSWORD_VAULT:?}/Proxmox - Packer API Token/credential"
export PROXMOX_PACKER_API_URI="op://${ONEPASSWORD_VAULT:?}/Proxmox - Packer API Token/hostname"

# export TF_VAR_ssh_pub_key="op://${TF_VAR_onepassword_vault:?}/Local Cluster - SSH Key/public key"
# export TF_VAR_node_user="op://${TF_VAR_onepassword_vault:?}/Local Cluster Template User/username"
# export TF_VAR_node_user_password="op://${TF_VAR_onepassword_vault:?}/Local Cluster Template User/password"

# The first argument is the target, the rest are options for the specified target
TARGET=$1
shift # Remove the first argument, leaving any additional arguments

# Function to run an ansible playbook
setup() {
	ln -s ../../.githooks/pre-push .git/hooks
	ln -s ../../.githooks/pre-commit .git/hooks
	python3 -m venv .venv
	source .venv/bin/activate
	pip install --upgrade pip
	pip install -r requirements.txt
}

# Function to run an ansible playbook
ansible_playbook() {
  source .venv/bin/activate
  op run -- ansible-playbook "$@"
}

curl_test() {
  source .venv/bin/activate
  curl -k  \
    -H "Content-Type: application/json" \
    -H "User-Agent	Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
    -H "Authorization: PVEAPITOKEN=$(op read "${PROXMOX_PACKER_API_TOKEN_ID:?}")=$(op read "${PROXMOX_PACKER_API_TOKEN_SECRET:?}")" \
    -X GET "$(op read "${PROXMOX_PACKER_API_URI:?}")/nodes/pve/storage/qemu"
}


# Usage function to display help for the script
usage() {
  echo "Usage: $0 {setup|ansible-playbook} [options]"
  echo "Mimics the functionality of a Makefile for Terraform."
}
# Main case switch for the script
case "$TARGET" in
  setup)
    setup "$@"
  ;;
  ansible-playbook)
    ansible_playbook "$@"
  ;;
  test)
    curl_test "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac

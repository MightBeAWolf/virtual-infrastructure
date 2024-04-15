#!/bin/bash

TARGET="${1:?}"
# PROXMOX_CLUSTER_NODE="pve"
PROXMOX_CLUSTER_NODE="${2:?}"
# PROXMOX_TEMPLATE_ID="8000"
PROXMOX_TEMPLATE_ID="${3:?}"
shift 3

# Secrets
ONEPASSWORD_VAULT="Local Cluster"
export PROXMOX_URL="op://${ONEPASSWORD_VAULT:?}/Proxmox - Packer API Token/hostname"
export PROXMOX_TOKEN="op://${ONEPASSWORD_VAULT:?}/Proxmox - Packer API Token/credential"
export PROXMOX_USERNAME="op://${ONEPASSWORD_VAULT:?}/Proxmox - Packer API Token/username"

export PKR_VAR_ssh_fullname="op://${ONEPASSWORD_VAULT:?}/Local Cluster Template User/fullname"
export PKR_VAR_ssh_username="op://${ONEPASSWORD_VAULT:?}/Local Cluster Template User/username"
export PKR_VAR_ssh_password="op://${ONEPASSWORD_VAULT:?}/Local Cluster Template User/password"


# Packer template file
PACKER_TEMPLATE="template.pkr.hcl"

get_unused_port(){
  for port in $(seq 49152 65535); do
    # Check if the port is not being used by any process
    if ! ss -tuln | grep -q ":$port "; then
        # Check if the port is not explicitly allowed or blocked by firewalld
        if ! firewall-cmd --list-ports | grep -q "$port/tcp"; then
            echo "${port:?}"
            break # Stop the loop once an available port is found
        fi
    fi
  done
}

# Function for packer verify
packer_verify() {
  op run -- packer validate \
    -var "proxmox_cluster_node=${PROXMOX_CLUSTER_NODE:?}" \
    -var "proxmox_template_id=${PROXMOX_TEMPLATE_ID:?}" \
    "$@" \
    "${PACKER_TEMPLATE:?}"
}

# Function for packer build
packer_build() {
  op run -- packer build \
    -var "proxmox_cluster_node=${PROXMOX_CLUSTER_NODE:?}" \
    -var "proxmox_template_id=${PROXMOX_TEMPLATE_ID:?}" \
    "$@" \
    "${PACKER_TEMPLATE:?}"
}

# Usage function to display help for the script
usage() {
  echo "Usage: $0 {validate|verify|build} [options]"
  echo "Mimics the functionality of a Makefile for Packer."
}
# Main case switch for the script
case "$TARGET" in
  verify|validate)
    packer_verify "$@"
  ;;
  build)
    packer_build "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac


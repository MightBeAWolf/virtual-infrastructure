#!/bin/bash
source "$(realpath "${BASH_SOURCE[0]}" | xargs -I{} dirname {})/secrets.env"
# Check that the secret credentials are present
if [[ -z "${PROXMOX_API_TOKEN_ID}" ]]; then
  echo -e "\e[91mMissing the environment secret PROXMOX_API_TOKEN_ID!\e[39m" >&2
  echo -e "\e[91mThis should be defined for you personally in secrets.env\e[39m" >&2
  echo -e "\e[91mSee the README.md for more information!\e[39m" >&2
  exit 1
fi
if [[ -z "${PROXMOX_API_SECRET}" ]]; then
  echo -e "\e[91mMissing the environment secret PROXMOX_API_SECRET!\e[39m" >&2
  echo -e "\e[91mThis should be defined for you personally in secrets.env\e[39m" >&2
  echo -e "\e[91mSee the README.md for more information!\e[39m" >&2
  exit 1
fi

export PROXMOX_USERNAME="${PROXMOX_API_TOKEN_ID}"
export PROXMOX_TOKEN="${PROXMOX_API_SECRET}"


export PKR_VAR_guest_username="${PROXMOX_VM_TEMPLATE_USER}"
export PKR_VAR_guest_password="${PROXMOX_VM_TEMPLATE_PASSWD}"

TARGET="${1:?}"
# PROXMOX_CLUSTER_NODE="pve"
PROXMOX_CLUSTER_NODE="${2:?}"
# PROXMOX_TEMPLATE_ID="8000"
PROXMOX_TEMPLATE_ID="${3:?}"
shift 3

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
    -var "id=${PROXMOX_TEMPLATE_ID:?}" \
    "$@" \
    "${PACKER_TEMPLATE:?}"
}

packer_init() {
  op run -- packer init \
    -var "proxmox_cluster_node=${PROXMOX_CLUSTER_NODE:?}" \
    -var "id=${PROXMOX_TEMPLATE_ID:?}" \
    "$@" \
    "${PACKER_TEMPLATE:?}"
}

# Function for packer build
packer_build() {
  op run -- packer build \
      -var "proxmox_cluster_node=${PROXMOX_CLUSTER_NODE:?}" \
      -var "id=${PROXMOX_TEMPLATE_ID:?}" \
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
  init)
    packer_init "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac


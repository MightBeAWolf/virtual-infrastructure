#!/bin/bash

# Customization
PROXMOX_CLUSTER_NODE="pve"
PROXMOX_TEMPLATE_ID="8000"

# Secrets
ONEPASSWORD_VAULT="Local Cluster"
export PROXMOX_URL="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/hostname"
export PROXMOX_TOKEN="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/credential"
export PROXMOX_USERNAME="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/tokenid"

# export PKR_VAR_ssh_fullname="op://${ONEPASSWORD_VAULT:?}/Local Cluster Template User/fullname"
# export PKR_VAR_ssh_username="op://${ONEPASSWORD_VAULT:?}/Local Cluster Template User/username"
# export PKR_VAR_ssh_password="op://${ONEPASSWORD_VAULT:?}/Local Cluster Template User/password"

# The first argument is the target, the rest are options for terraform
TARGET=$1
shift # Remove the first argument, leaving any additional arguments

# terraform template file
TERRAFORM_CONF="k3s-cluster.tf"

# Function for terraform verify
terraform-format() {
  op run -- terraform validate \
    "$@" \
    "${TERRAFORM_CONF:?}"
}

# Function for terraform verify
terraform-validate() {
  op run -- terraform validate \
    "$@" \
    "${TERRAFORM_CONF:?}"
}

# Function for terraform verify
terraform-init() {
  op run -- terraform validate \
    "$@" \
    "${TERRAFORM_CONF:?}"
}

# Function for terraform build
terraform_apply() {
  op run -- terraform apply \
    "$@" \
    "${TERRAFORM_CONF:?}"
}

# Usage function to display help for the script
usage() {
  echo "Usage: $0 {validate|verify|format|init|apply} [options]"
  echo "Mimics the functionality of a Makefile for Terraform."
}
# Main case switch for the script
case "$TARGET" in
  format)
    terraform-format "$@"
  ;;
  verify|validate)
    terraform-validate "$@"
  ;;
  init)
    terraform-init "$@"
  ;;
  apply)
    terraform_build "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac


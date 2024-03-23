#!/bin/bash

# Customization
PROXMOX_CLUSTER_NODE="pve"
PROXMOX_TEMPLATE_ID="8000"

# Secrets
ONEPASSWORD_VAULT="Local Cluster"
export TF_VAR_pm_api_url="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/hostname"
export TF_VAR_pm_user="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/username"
export TF_VAR_pm_api_token_id="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/tokenid"
export TF_VAR_pm_api_token_secret="op://${ONEPASSWORD_VAULT:?}/Proxmox - Terraform Provider/credential"

# The first argument is the target, the rest are options for terraform
TARGET=$1
shift # Remove the first argument, leaving any additional arguments

# Function for terraform verify
terraform-validate() {
  op run -- terraform validate "$@"
}

# Function for terraform verify
terraform-init() {
  op run -- terraform init "$@"
}

# Function for terraform verify
terraform-plan() {
  op run -- terraform plan "$@"
}

# Function for terraform apply
terraform_apply() {
  op run -- terraform apply "$@"
}

# Function for terraform destroy
terraform_destroy() {
  op run -- terraform destroy "$@"
}

# Usage function to display help for the script
usage() {
  echo "Usage: $0 {validate|verify|init|plan|apply} [options]"
  echo "Mimics the functionality of a Makefile for Terraform."
}
# Main case switch for the script
case "$TARGET" in
  verify|validate)
    terraform-validate "$@"
  ;;
  init)
    terraform-init "$@"
  ;;
  plan)
    terraform-plan "$@"
  ;;
  apply)
    terraform_apply "$@"
  ;;
  destroy)
    terraform_destroy "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac


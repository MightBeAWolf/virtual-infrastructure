#!/bin/bash


# Secrets
export TF_VAR_pm_api_token_id="${PROXMOX_API_TOKEN_ID:?}"
export TF_VAR_pm_api_token_secret="${PROXMOX_API_SECRET:?}"

if [[ ! -f "/home/$USER/.ssh/id_ed25519.pub" ]]; then
  echo -e "\e91mFailed to find /home/$USER/.ssh/id_ed25519.pub!\e[39m" >&2
  exit 1
fi
export TF_VAR_ssh_pub_key="$(cat /home/$USER/.ssh/id_ed25519.pub)"
export TF_VAR_node_user="op://I.T./Proxmox Cluster Template User/username"
export TF_VAR_node_user_password="op://I.T./Proxmox Cluster Template User/password"

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

# Function for terraform destroy
terraform_output() {
  op run -- terraform refresh
  op run -- terraform output "$@"
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
  output)
    terraform_output "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac


#!/bin/bash


# Secrets
export TF_VAR_onepassword_vault="Local Cluster"
export TF_VAR_onepassword_service_token="op://${TF_VAR_onepassword_vault:?}/Local Cluster - Terraform Service Account/credential"
export TF_VAR_onepassword_cli_path="$(which op)"

export TF_VAR_pm_api_token_id="${PROXMOX_API_TOKEN_ID:?}"
export TF_VAR_pm_api_token_secret="${PROXMOX_API_SECRET:?}"

export TF_VAR_ssh_pub_key="op://${TF_VAR_onepassword_vault:?}/Local Cluster - SSH Key/public key"
export TF_VAR_node_user="op://${TF_VAR_onepassword_vault:?}/Local Cluster Template User/username"
export TF_VAR_node_user_password="op://${TF_VAR_onepassword_vault:?}/Local Cluster Template User/password"

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


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
if [[ -z "${PROXMOX_API_HOSTNAME}" ]]; then
  echo -e "\e[91mMissing the environment secret PROXMOX_API_HOSTNAME!\e[39m" >&2
  echo -e "\e[91mThis should be defined for you personally in secrets.env\e[39m" >&2
  echo -e "\e[91mSee the README.md for more information!\e[39m" >&2
  exit 1
fi

export ANSIBLE_FORCE_COLOR=True

# The first argument is the target, the rest are options for the specified target
TARGET=$1
shift # Remove the first argument, leaving any additional arguments

get_latest_python() {
  compgen -c python \
    | egrep 'python[0-9\.]*$' \
    | sort -uV \
    | tail -n 1
}

# Function to run an ansible playbook
setup() {
	ln -s ../../.githooks/pre-push .git/hooks
	ln -s ../../.githooks/pre-commit .git/hooks
	$(get_latest_python) -m venv .venv
	source .venv/bin/activate
	pip install --upgrade pip
	pip install -r requirements.txt
}

# Function to run an ansible playbook
ansible_playbook() {
  source .venv/bin/activate
  op run -- ansible-playbook "$@"
}

credential_test() {
  source .venv/bin/activate
  if op run -- curl -v -k  \
    -H "Content-Type: application/json" \
    -H "Authorization: PVEAPIToken=$(op read "${PROXMOX_API_TOKEN_ID:?}")=$(op read "${PROXMOX_API_SECRET:?}")" \
    "$(op read "${PROXMOX_API_HOSTNAME:?}")/nodes"
  then
    echo -e "\e[92mCredential test passed\e[39m" >&2
  else
    echo -e "\e[91mCredential test failed\e[39m" >&2
    exit 1
  fi
}


# Usage function to display help for the script
usage() {
  echo "Usage: $0 {setup|ansible-playbook|credential-test} [options]"
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
  credential-test)
    credential_test "$@"
  ;;
  *)
    echo "Error: Unknown target '$TARGET'"
    usage
    exit 1
  ;;
esac

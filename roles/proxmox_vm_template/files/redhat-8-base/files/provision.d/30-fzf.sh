#!/bin/bash

# Purpose: This script clones the fzf repository and installs fzf.
# It follows best practices in argument parsing, error handling, and input validation.

# Default values
REPO_URL="https://github.com/junegunn/fzf.git"
INSTALL_DIR="/etc/skel/.fzf"

# Help function using HEREDOC for documentation
help() {
    cat << HELP
Usage: ${0##*/} [OPTIONS]

Options:
  --install-dir <path>  Set the installation directory (default: ${INSTALL_DIR}).
  -h, --help            Display this help and exit.

This script clones the fzf repository and installs fzf.
HELP
}

# Error and log functions
error_log() {
    echo -e "\033[31mERROR:\033[0m ${1}" >&2
}

log() {
    echo -e "\033[32mLOG:\033[0m ${1}"
}

# Argument parsing
PARAMS=()
while (( "$#" )); do
  case "${1}" in
    --install-dir)
      if [[ -n "${2}" ]] && [[ ${2:0:1} != "-" ]]; then
        INSTALL_DIR=${2}
        shift 2
      else
        error_log "--install-dir requires a path"
        exit 1
      fi
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -*|--*)
      error_log "Unsupported flag ${1}"
      exit 1
      ;;
    *)
      PARAMS+=("${1}")
      shift
      ;;
  esac
done
set -- "${PARAMS[@]}"

# Set options
set -u

# Input validation
if [[ ! -d "${INSTALL_DIR}" ]]; then
  mkdir -p "${INSTALL_DIR}" || {
    error_log "Failed to create installation directory ${INSTALL_DIR}"
    exit 1
  }
fi

log "Cloning fzf repository into ${INSTALL_DIR}"
if git clone "${REPO_URL}" "${INSTALL_DIR}"; then
  log "Successfully cloned fzf"
else
  error_log "Failed to clone fzf"
  exit 1
fi

log "Running fzf install script"
if ! "${INSTALL_DIR}/install" --all --no-update-rc; then
  error_log "fzf installation failed"
  exit 1
fi

cat >> /etc/skel/.bashrc << HEREDOC
if [[ -e "\${HOME:?}/.fzf/shell" ]]; then
  export PATH="\$HOME/.fzf/bin:\$PATH"

  # Auto-completion
  # ---------------
  source "\${HOME:?}/.fzf/shell/completion.bash"

  # Key bindings
  # ------------
  source "\${HOME:?}/.fzf/shell/key-bindings.bash"
fi
HEREDOC

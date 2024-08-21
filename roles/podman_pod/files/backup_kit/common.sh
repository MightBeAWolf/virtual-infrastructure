#!/bin/bash
# Silicon Technologies Inc. CONFIDENTIAL
# Unpublished Copyright (c) 2023 Silicon Technologies Inc., All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains the property of Silicon
# Technologies Inc. The intellectual and technical concepts contained
# herein are proprietary to Silicon Technologies Inc. and may be covered by U.S. and
# Foreign Patents, patents in process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is strictly forbidden
# unless prior written permission is obtained from Silicon Technologies Inc.  Access to the
# source code contained herein is hereby forbidden to anyone except current Silicon Technologies
# Inc. employees, managers or contractors who have executed Confidentiality andNon-disclosure
# agreements explicitly covering such access.
#
# The copyright notice above does not evidence any actual or intended publication or disclosure
# of this source code, which includes information that is confidential and/or proprietary,
# and is a trade secret, of  Silicon Technologies Inc.   ANY REPRODUCTION, MODIFICATION,
# DISTRIBUTION, PUBLIC  PERFORMANCE, OR PUBLIC DISPLAY OF OR THROUGH USE  OF THIS  SOURCE
# CODE  WITHOUT  THE EXPRESS WRITTEN CONSENT OF COMPANY IS STRICTLY PROHIBITED, AND IN
# VIOLATION OF APPLICABLE LAWS AND INTERNATIONAL TREATIES.  THE RECEIPT OR POSSESSION
# OF  THIS SOURCE CODE AND/OR RELATED INFORMATION DOES NOT CONVEY OR IMPLY ANY RIGHTS TO
# REPRODUCE, DISCLOSE OR DISTRIBUTE ITS CONTENTS, OR TO MANUFACTURE, USE, OR SELL ANYTHING
# THAT IT  MAY DESCRIBE, IN WHOLE OR IN PART.
error_log() {
  echo -e "\e[91mError: ${1:?}\e[39m" >&2
}

check_op_signin() {
  if op whoami &>/dev/null; then
    return
  fi
  if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN}" ]]; then 
    error_log "$(cat <<-HEREDOC
The OP_SERVICE_ACCOUNT_TOKEN has not been set!
This must be set in the environment in order to access the various credentials
and secrets required to backup offsite.

See the Confluence document for more info:
https://sti.atlassian.net/l/cp/mrzt7D6s
HEREDOC
)"
    exit 1

  fi
  if ! op user get --me > /dev/null 2>&1; then
    error_log "$(cat <<-HEREDOC
The OP_SERVICE_ACCOUNT_TOKEN failed to validate!
An attempt to use 'op user get --me' has failed. Check to make sure that
OP_SERVICE_ACCOUNT_TOKEN is still valid and hasn't been revoked.
HEREDOC
)"
    exit 1
  fi
}

check_for_restic_repo(){
  if [ -z "$SSH_AUTH_SOCK" ]; then 
    error_log "SSH agent has not been started"
  fi
  # Call the function to add the key with the passphrase
  add_key_with_passphrase "${SSH_KEY:-/var/backupsys/.ssh/id_ed25519}" "${OP_REFERENCE_SSH_PASSPHRASE:?}"
  if /var/backupsys/bin/restic -r "${REPOSITORY:?}" snapshots; then
      echo "Repository exists. Proceeding with backup."
  elif [[ -z "$DRY_RUN" ]]; then
      echo "Repository does not exist. Initializing."
      /var/backupsys/bin/restic -r "${REPOSITORY:?}" init
  else
      echo "Repository does not exist. It would be initialized and fully backed up"
      exit 0
  fi
}

apply_restic_retention_policy(){
  if [ -z "$SSH_AUTH_SOCK" ]; then 
    error_log "SSH agent has not been started"
  fi
  add_key_with_passphrase "${SSH_KEY:-/var/backupsys/.ssh/id_ed25519}" "${OP_REFERENCE_SSH_PASSPHRASE:?}"
  # Prune any old snapshots outside of the retention policy
  # Only prune snapshots that don't have any tags.
  /var/backupsys/bin/restic -r "${REPOSITORY:?}" forget --prune \
    "${DRY_RUN[@]}" \
    --tag '' \
    "${RETENTION_POLICY[@]}"

}

# Function to handle SSH key passphrase with Expect
add_key_with_passphrase() {
  local key_file=$1
  local op_secret_ref=$2
  local max_retries=3
  local attempt=0

  if [ -z "$SSH_AUTH_SOCK" ]; then 
    error_log "SSH agent is not running"
    return 1
  fi

  if [ ! -f "$key_file" ]; then
    error_log "Key file $key_file not found"
    return 1
  fi

  # Check if the key is already added
  if ssh-add -l | grep -wF "${key_file}"; then
    echo "Key ${key_file} already added."
    return 0
  fi

  while (( attempt < max_retries )); do
    /usr/bin/expect <<-HEREDOC
      set timeout 10
      set passphrase [exec op read "$op_secret_ref"]
      spawn ssh-add -t 600 "$key_file"
      expect {
        "Enter passphrase for $key_file:" {
          send "\$passphrase\r"
          exp_continue
        }
        eof {
          catch wait result
          lassign \$result pid spawn_id os_error actual_exit_code
          if { \$actual_exit_code != 0 } {
            puts "Failed to add key. Error: \$os_error"
          }
          exit \$actual_exit_code
        }
      }
HEREDOC

    #shellcheck disable=SC2181
    if [[ "$?" -eq 0 ]]; then
      echo "Key successfully added."
      return 0
    fi

    ((attempt++))
    echo "Attempt $attempt failed. Retrying..."
    sleep 1
  done

  error_log "Failed to add the key after $max_retries attempts."
  return 1
}

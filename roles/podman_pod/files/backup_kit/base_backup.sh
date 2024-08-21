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
###############################################################################################
#################################### B Utility Functions ######################################
###############################################################################################
SCRIPT_DIR="$(realpath "${BASH_SOURCE[0]}" | xargs -I{} dirname {})"
# shellcheck source=./common.sh
source "${SCRIPT_DIR:?}/common.sh"
###############################################################################################
##################################### D Validate Inputs #######################################
###############################################################################################

if [[ -z "${REMOTE_REPO_NAME}" ]]; then 
  error_log "Invalid configuration for REMOTE_REPO_NAME '${REMOTE_REPO_NAME}' "
  exit 1
fi
if [[ -z "${REPOSITORY}" ]]; then 
  error_log "Invalid configuration for REPOSITORY '${REPOSITORY}' "
  exit 1
fi
if [[ -z "${SOURCE_PATHS[@]}" ]]; then 
  error_log "Invalid configuration for SOURCE_PATHS '${SOURCE_PATHS[@]}' "
  exit 1
fi
if [[ -z "${EXCLUDE_POLICIES[*]}" ]]; then 
  error_log "Invalid configuration for EXCLUDE_POLICIES '${EXCLUDE_POLICIES}' "
  exit 1
fi
if [[ -z "${RETENTION_POLICY[*]}" ]]; then 
  error_log "Invalid configuration for RETENTION_POLICY '${RETENTION_POLICY}' "
  exit 1
fi
if [[ -z "${OP_REFERENCE_REPO_PASSWORD}" ]]; then 
  error_log "Invalid configuration for OP_REFERENCE_REPO_PASSWORD '${OP_REFERENCE_REPO_PASSWORD}' "
  exit 1
fi
if [[ -z "${OP_REFERENCE_SSH_PASSPHRASE}" ]]; then 
  error_log "Invalid configuration for OP_REFERENCE_SSH_PASSPHRASE '${OP_REFERENCE_SSH_PASSPHRASE}' "
  exit 1
fi

check_op_signin
###############################################################################################
#################################### E Execute Operations #####################################
###############################################################################################
# Start ssh-agent
eval "$(ssh-agent -s)"

# Retrieve Restic repository password from 1Password
RESTIC_PASSWORD=$(op read "${OP_REFERENCE_REPO_PASSWORD:?}")
export RESTIC_PASSWORD # Done seperatly as recommended by shellcheck SC2155

# Check if the repo exists on the destination server.
check_for_restic_repo

# Check if there is a pre_backup_processing function, and if so, run it
if [[ "$(type -t pre_backup_processing)" == "function" ]]; then
  echo "Executing Backup Preprocessing"
  if ! pre_backup_processing; then 
    error_log "Failed while executing backup preprocessing"
    exit 1
  fi
fi

# Call the function to re-add the ssh key with the passphrase. This must be
# called again as there is an expiration on how long the key is stored, and we
# have to be prepared for the previous steps of the script to take longer than
# the expiration
add_key_with_passphrase "${SSH_KEY:-/var/backupsys/.ssh/id_ed25519}" "${OP_REFERENCE_SSH_PASSPHRASE:?}"
# Perform the backup
if ! /var/backupsys/bin/restic -r "${REPOSITORY:?}" backup "${SOURCE_PATHS[@]}" \
  --verbose \
  "${DRY_RUN[@]}" \
  "${EXCLUDE_POLICIES[@]}" \
  "${ADDITIONAL_BACKUP_ARGS[@]}"
then
  error_log "Failed to backup ${SOURCE_PATHS[@]} to '${REPOSITORY:?}'"
  BACKUP_FAILED=TRUE
fi



# Check if there is a post_backup_processing function, and if so, run it
if [[ "$(type -t post_backup_processing)" == "function" ]]; then
  echo "Executing Backup Post Processing"
  if ! post_backup_processing; then 
    error_log "Failed while executing backup postprocessing"
  fi
fi

if [[ -n "${BACKUP_FAILED}" ]]; then
  exit 1
fi

# Apply the restic retention policy
apply_restic_retention_policy


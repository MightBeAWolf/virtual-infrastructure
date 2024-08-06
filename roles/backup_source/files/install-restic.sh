#!/bin/bash
export RESTIC_VERSION_GIT_TAG="v0.16.2"
export ARCH="linux_386"

RELEASE_JSON="$(curl -s https://api.github.com/repos/restic/restic/releases)"
VERSION_JSON="$(jq -r ".[] | select(.tag_name==\"${RESTIC_VERSION_GIT_TAG:?}\")" <<< "${RELEASE_JSON:?}")"
ARCHITECTURE_JSON="$(jq -r ".assets[] | select(.name | contains(\"${ARCH:?}\"))" <<< "${VERSION_JSON:?}")"
INSTALL_URL="$(jq -r ".browser_download_url" <<< "${ARCHITECTURE_JSON}")"
INSTALL_FILE="${INSTALL_URL##*/}"

if [[ ~backupsys/bin/restic ]]; then
  rm ~backupsys/bin/restic
fi

INSTALL_COMMAND="$(cat << HEREDOC
cd ~backupsys && \
curl -LO "${INSTALL_URL:?}" && \
bzip2 -f -d "${INSTALL_FILE:?}" && \
mv "${INSTALL_FILE%.bz2}" ./bin/restic
HEREDOC
)"
sudo -u backupsys bash -c "${INSTALL_COMMAND:?}"

chown root:backupsys ~backupsys/bin/restic
chmod 0750 ~backupsys/bin/restic
setcap cap_dac_read_search=+ep ~backupsys/bin/restic

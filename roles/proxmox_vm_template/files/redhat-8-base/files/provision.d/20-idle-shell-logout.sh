#!/bin/bash
# Set idle timeout for shell logins
PROFILE_FILE=/etc/profile.d/20-idle-shell-logout.sh
cat > "${PROFILE_FILE:?}" << HEREDOC
# Linux bash shell allows you to define the TMOUT environment variable. Set
# TMOUT to log users out after a period of inactivity automatically. The value is
# defined in seconds.
TMOUT=300 # Set to 5 minutes
readonly TMOUT
export TMOUT
HEREDOC
chown root:root "${PROFILE_FILE:?}"
chmod 0644 "${PROFILE_FILE:?}"

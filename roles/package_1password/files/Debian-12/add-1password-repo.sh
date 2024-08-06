#!/bin/bash
if [[ ! -f /usr/share/keyrings/1password-archive-keyring.gpg ]]; then
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
fi

if [[ ! -f /etc/debsig/policies/AC2D62742012EA22/1password.pol ]]; then
mkdir -p /etc/debsig/policies/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
  | tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
fi

if [[ ! -f /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg ]]; then
mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  | gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
fi

cat > /etc/apt/sources.list.d/1password.list << HEREDOC
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main"
HEREDOC


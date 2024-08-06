#!/bin/bash
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | gpg --dearmor --batch --yes --output /usr/share/keyrings/1password-archive-keyring.gpg

mkdir -p /etc/debsig/policies/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
  | tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | gpg --dearmor --batch --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" > /etc/apt/sources.list.d/1password.list

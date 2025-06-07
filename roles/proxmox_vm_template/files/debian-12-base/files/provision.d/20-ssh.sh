#!/bin/bash
# Setup SSH
mv /tmp/config.d/sshd_config /etc/ssh/sshd_config
chmod 0600 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config


#!/bin/bash
# Setup SSSD
mv /tmp/config.d/sssd.conf /etc/sssd/sssd.conf
mv /tmp/config.d/nsswitch.conf /etc/nsswitch.conf
mv /tmp/config.d/pam.d.system-auth /etc/pam.d/system-auth
chmod 0600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf /etc/nsswitch.conf /etc/pam.d/system-auth

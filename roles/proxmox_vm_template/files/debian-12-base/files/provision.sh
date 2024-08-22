# Set the host up with OpenLDAP/SSSD Identities
(cat | sudo tee /etc/sssd/sssd.conf > /dev/null) << 'HEREDOC'
[sssd]
services = nss, pam, autofs
config_file_version = 2
domains = default

[nss]
override_shell = /bin/bash

[pam]
offline_credentials_expiration = 60

[domain/default]
id_provider = ldap 
autofs_provider = ldap
auth_provider = ldap
chpass_provider = ldap
ldap_uri = ldaps://ldap.local.silicontech.us
ldap_search_base = dc=sti,dc=local
ldap_tls_reqcert = never
HEREDOC
sudo chmod 0600 /etc/sssd/sssd.conf

(cat | sudo tee /etc/openldap/ldap.conf > /dev/null) << 'HEREDOC'
# See ldap.conf(5) for details
# This file should be world readable but not world writable.
BASE dc=sti,dc=local
URI ldaps://ldap.local.silicontech.us
TLS_REQCERT never
TLS_CACERTDIR /etc/openldap/cacerts
HEREDOC

(cat | sudo tee /etc/pam.d/common-session > /dev/null) << 'HEREDOC'
# /etc/pam.d/common-session - session-related modules common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of modules that define tasks to be performed
# at the start and end of interactive sessions.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

# here are the per-package modules (the "Primary" block)
session	[default=1]			pam_permit.so
# here's the fallback if no module succeeds
session	requisite			pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
session	required			pam_permit.so
# and here are more per-package modules (the "Additional" block)
session	required	pam_unix.so 
session	optional	pam_sss.so 
session required	pam_mkhomedir.so skel=/etc/skel/ umask=0022
session	optional	pam_systemd.so 
# end of pam-auth-update confi
HEREDOC

(cat | sudo tee /etc/sudoers.d/admin > /dev/null) << 'HEREDOC'
# Add the admin group to sudo
#Enable admin users to use sudo
%admin	ALL=(ALL)	ALL
HEREDOC

# Setup auto logout for IDLE shells
(cat | sudo tee /etc/profile.d/20-idle-shell-logout > /dev/null) << 'HEREDOC'
# Linux bash shell allows you to define the TMOUT environment variable. Set
# TMOUT to log users out after a period of inactivity automatically. The value is
# defined in seconds.
TMOUT=300 # Set to 5 minutes
readonly TMOUT
export TMOUT
HEREDOC


# General preparation for the template
sudo -n rm /etc/ssh/ssh_host_*
sudo -n truncate -s 0 /etc/machine-id

# Prepare apt for the template
sudo -n apt -y autoremove --purge
sudo -n apt -y clean
sudo -n apt -y autoclean

# Prepare cloud-init for the template
sudo -n cloud-init clean
sudo -n rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
sudo -n mv /tmp/99-pve.cfg            /etc/cloud/cloud.cfg.d/99-pve.cfg
sudo -n mv /tmp/cloud.cfg             /etc/cloud/cloud.cfg

# Move misc configuration into their respective locations
sudo -n mv /tmp/50unattended-upgrades /etc/apt/apt.conf.d
sudo -n mv /tmp/20auto-upgrades       /etc/apt/apt.conf.d

sudo -n sync
sudo rm /etc/sudoers.d/$USER

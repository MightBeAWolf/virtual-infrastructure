# General preparation for the template
rm /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id

# Prepare apt for the template
apt -y autoremove --purge
apt -y clean
apt -y autoclean

# Prepare cloud-init for the template
cloud-init clean
rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
mv /tmp/confid.g/99-pve.cfg            /etc/cloud/cloud.cfg.d/99-pve.cfg
mv /tmp/confid.g/cloud.cfg             /etc/cloud/cloud.cfg

sync
rm "/etc/sudoers.d/${SUDO_USER:-${USER}}"


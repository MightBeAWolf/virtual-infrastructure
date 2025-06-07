
# General preparation for the template
rm /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id

# Prepare dnf for the template
dnf -y autoremove
dnf -y clean all

# Prepare cloud-init for the template
cloud-init clean --logs

# rm -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg # TODO KEEP OR REMOVE?
mv /tmp/config.d/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg
mv /tmp/config.d/cloud.cfg /etc/cloud/cloud.cfg

sync
rm "/etc/sudoers.d/${SUDO_USER:-${USER}}"

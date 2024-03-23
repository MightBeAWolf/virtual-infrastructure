
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

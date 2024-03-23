
sudo -n rm /etc/ssh/ssh_host_*
sudo -n truncate -s 0 /etc/machine-id
sudo -n apt -y autoremove --purge
sudo -n apt -y clean
sudo -n apt -y autoclean
sudo -n cloud-init clean
sudo -n rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
sudo -n sync
sudo -n cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg

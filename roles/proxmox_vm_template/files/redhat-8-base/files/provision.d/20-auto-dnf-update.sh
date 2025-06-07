# Automatic updates
#

# Move files and set permissions
mv /tmp/config.d/auto-dnf-update/automatic.conf /etc/dnf/automatic.conf
chmod 0600 /etc/dnf/automatic.conf
mv /tmp/config.d/auto-dnf-update/dnf-automatic-restart /usr/sbin/dnf-automatic-restart
chmod 0744 /usr/sbin/dnf-automatic-restart
mkdir -p /etc/systemd/system/dnf-automatic.service.d
mv /tmp/config.d/auto-dnf-update/override.conf /etc/systemd/system/dnf-automatic.service.d/override.conf
chmod 0644 /etc/systemd/system/dnf-automatic.service.d/override.conf
rm -rf /tmp/config.d/auto-dnf-update

# Set the SELinux label so that it can be executed
semanage fcontext -a -t bin_t /usr/sbin/dnf-automatic-restart
restorecon -Rv /usr/sbin/dnf-automatic-restart

# Set root ownership
chown root:root /etc/dnf/automatic.conf \
  /usr/sbin/dnf-automatic-restart \
  /etc/systemd/system/dnf-automatic.service.d/override.conf

# Enable the update timer
systemctl enable dnf-automatic.timer

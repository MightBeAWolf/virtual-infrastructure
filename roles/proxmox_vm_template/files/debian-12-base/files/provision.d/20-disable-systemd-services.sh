#!/bin/bash

# Define services to disable
SERVICES_TO_STOP=(
    avahi-daemon.service
    cups.service
    cups.socket
    ModemManager.service
    rpcbind.service
    rpcbind.socket
    fwupd.service
    wpa_supplicant.service
)

# Iterate over services to disable
for service in "${SERVICES_TO_STOP[@]}"; do
    if systemctl is-enabled --quiet "$service"; then
        echo "Disabling $service"
        systemctl disable --now "$service"
    else
        echo "$service already disabled"
    fi
done


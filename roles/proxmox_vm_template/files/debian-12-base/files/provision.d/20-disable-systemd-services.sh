#!/bin/bash

# Define services to disable
SERVICES_TO_STOP=(
    ModemManager.service
    rpcbind.socket
    rpcbind.service
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


#!/bin/bash
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | \
  gpg --dearmor | \
  tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list

apt-get update  -y
apt-get install -y alloy

rm /etc/alloy/config.alloy
mkdir /etc/alloy/config.d

cat > /etc/alloy/config.d/journald.alloy << HEREDOC
loki.source.journal "read" {
  path = "/var/log/journal"
  labels = {
    service_name = "systemd-journal",
    host         = "$(hostname -f)",
  }
  forward_to   = [loki.write.endpoint.receiver]
  relabel_rules = loki.relabel.journal.rules
}

loki.relabel "journal" {
  forward_to = []
  rule {
    source_labels = ["__journal__systemd_unit"]
    regex         = \`alloy\.service\`
    action        = "drop"
  }
  rule {
    source_labels = ["__journal_priority"]
    target_label  = "priority"
  }
  rule {
    source_labels = ["__journal__systemd_unit"]
    target_label  = "unit"
  }
}

loki.write "endpoint" {
  endpoint{
    url = "https://monitoring.local.wolfbox.dev/loki/loki/api/v1/push"
  }
}
HEREDOC

cat > /etc/default/alloy << HEREDOC
CONFIG_FILE="/etc/alloy/config.d"

# User-defined arguments to pass to the run command.
CUSTOM_ARGS=""

# Restart on system upgrade. Defaults to true.
RESTART_ON_UPGRADE=true
HEREDOC

systemctl daemon-reload
systemctl enable --now alloy.service


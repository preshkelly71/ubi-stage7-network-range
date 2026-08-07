#!/bin/sh
set -eu
# UBI Stage 7 - sensor init script
# Suricata and iproute2 are pre-baked into the soc-sensor image.

# eth1 is the SPAN capture port — no IP, promiscuous mode
ip link set eth1 promisc on
ip link set eth1 up

# eth2 is the management/collection link
ip address add 10.81.90.2/29 dev eth2 2>/dev/null || true
ip route replace default via 10.81.90.1 dev eth2

# Create log directory if it doesn't exist (bind mount target)
mkdir -p /var/log/suricata

# Copy in our config and rules if the bind mounts didn't take
if [ ! -f /etc/suricata/suricata.yaml ]; then
  cp /etc/suricata/suricata.yaml.dist /etc/suricata/suricata.yaml 2>/dev/null || true
fi

# Start Suricata in pcap mode on eth1 (the SPAN target)
suricata -c /etc/suricata/suricata.yaml -i eth1 -D 2>/dev/null || \
  suricata -c /etc/suricata/suricata.yaml -i eth1 2>&1 &


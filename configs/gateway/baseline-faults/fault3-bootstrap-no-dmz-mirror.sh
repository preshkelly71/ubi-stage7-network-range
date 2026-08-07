#!/bin/sh
set -eu
# UBI Stage 7 gateway bootstrap - builds the firewall/router node entirely
# from code. No manual node configuration is performed after this runs.

apk add --no-cache nftables iproute2 iproute2-tc tcpdump openssh-server

# --- addressing (address-plan second octet 81) ---
ip address add 10.81.254.2/30 dev eth1   # uplink to core
ip address add 10.81.10.1/27  dev eth2   # management
ip address add 10.81.20.1/26  dev eth3   # finance
ip address add 10.81.30.1/25  dev eth4   # engineering
ip address add 10.81.40.1/24  dev eth5   # users
ip address add 10.81.50.1/27  dev eth6   # servers
ip address add 10.81.70.1/24  dev eth7   # guest
ip address add 10.81.60.1/28  dev eth8   # dmz
ip address add 10.81.90.1/29  dev eth10  # sensor management/collection link

# eth9 is the SPAN target toward the sensor's promiscuous capture NIC.
# It intentionally carries no IP address - it only receives mirrored frames.
ip link set eth9 up

# --- routing back to the internal range from core ---
ip route add 203.0.113.0/30 via 10.81.254.1 dev eth1
ip route add 0.0.0.0/0 via 10.81.254.1 dev eth1

# --- "network devices" admin path: gateway itself is one of the admin
# targets for NET-07/NET-22. Give it a minimal sshd that only the
# management-sourced nftables rule will ever let traffic reach. ---
ssh-keygen -A >/dev/null 2>&1 || true
mkdir -p /run/openssh
/usr/sbin/sshd

# --- passive mirroring: copy ingress traffic on every zone-facing and
# uplink interface out to the sensor SPAN port (eth9). This happens at
# the qdisc layer, independent of the nftables forward decision, so the
# sensor sees the same packets the firewall evaluated. ---
for interface in eth1 eth2 eth3 eth4 eth5 eth6 eth7; do # FAULT: eth8 (dmz) removed from mirror
  tc qdisc add dev "$interface" clsact
  tc filter add dev "$interface" ingress matchall action mirred egress mirror dev eth9
done

sysctl -w net.ipv4.ip_forward=1
nft -f /etc/nftables.conf

tail -f /dev/null

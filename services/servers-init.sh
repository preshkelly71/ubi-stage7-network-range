#!/bin/sh
set -eu
# The "servers" zone hosts the internal services referenced by the
# control-test-matrix. socat is pre-baked into the soc-servers image.

# centralized DNS - both UDP and TCP
( while true; do
    socat -T5 UDP4-LISTEN:53,reuseaddr,fork SYSTEM:'printf "internal-dns-udp-ok"'
  done ) &
( while true; do
    socat -T5 TCP4-LISTEN:53,reuseaddr,fork SYSTEM:'printf "internal-dns-tcp-ok"'
  done ) &

# NTP stand-in
( while true; do
    socat -T5 UDP4-LISTEN:123,reuseaddr,fork SYSTEM:'printf "ntp-ok"'
  done ) &

# payroll application (finance -> servers, NET-04)
( while true; do
    socat -T5 TCP4-LISTEN:8443,reuseaddr,fork SYSTEM:'printf "payroll-app-ok"'
  done ) &

# payroll database, assigned port (finance NET-16 / dmz relay NET-11)
( while true; do
    socat -T5 TCP4-LISTEN:5432,reuseaddr,fork SYSTEM:'printf "payroll-db-ok"'
  done ) &

# service on the "nonassigned" port too, so NET-24's denial
# is proven by the firewall, not by an absent listener.
( while true; do
    socat -T5 TCP4-LISTEN:5433,reuseaddr,fork SYSTEM:'printf "should-never-be-reached"'
  done ) &

# code service consumed by engineering (NET-05)
( while true; do
    socat -T5 TCP4-LISTEN:9418,reuseaddr,fork SYSTEM:'printf "code-service-ok"'
  done ) &

ip route replace default via 10.81.50.1

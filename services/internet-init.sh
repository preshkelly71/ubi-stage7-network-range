#!/bin/sh
set -eu
# Internet zone host — socat pre-baked into soc-host image.
# Provides a target for the internet-side tests to hit.

# Simple HTTP on port 80 (internet -> dmz test target)
( while true; do
    socat -T5 TCP4-LISTEN:80,reuseaddr,fork SYSTEM:'printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"'
  done ) &

# HTTPS on port 443
( while true; do
    socat -T5 TCP4-LISTEN:443,reuseaddr,fork SYSTEM:'printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"'
  done ) &


# UDP DNS responder on port 53 — replies to any UDP packet (for NET-01/NET-13)
( while true; do
    socat -T2 UDP4-RECVFROM:53,reuseaddr SYSTEM:'printf "dns-ok"'
  done ) &

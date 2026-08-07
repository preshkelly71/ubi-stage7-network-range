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

# UDP DNS responder on port 53 — persistent forked listener for NET-01/NET-13
socat -T5 UDP4-LISTEN:53,reuseaddr,fork SYSTEM:'printf "dns-ok"' &

# NTP responder on port 123 (for NET-29 users NTP return-path test)
socat -T5 UDP4-LISTEN:123,reuseaddr,fork SYSTEM:'printf "ntp-ok"' &

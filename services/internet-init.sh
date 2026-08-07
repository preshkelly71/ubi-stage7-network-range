#!/bin/sh
set -eu

# DNS UDP on port 53 (for guest/users DNS resolution tests)
( while true; do
    socat -T5 UDP4-LISTEN:53,reuseaddr,fork SYSTEM:'printf "dns-ok"'
  done ) &

# HTTP on port 80
( while true; do
    socat -T5 TCP4-LISTEN:80,reuseaddr,fork SYSTEM:'printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"'
  done ) &

# HTTPS on port 443
( while true; do
    socat -T5 TCP4-LISTEN:443,reuseaddr,fork SYSTEM:'printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"'
  done ) &

#!/bin/sh
set -eu
# DMZ hosts the public-facing web endpoint. socat pre-baked into soc-servers image.

( while true; do
    socat -T5 TCP4-LISTEN:443,reuseaddr,fork SYSTEM:'printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"'
  done ) &

ip route replace default via 10.81.60.1

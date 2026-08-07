#!/bin/sh
set -eu
# Management zone host — packages pre-baked into soc-host image.
ip route replace default via 10.81.10.1

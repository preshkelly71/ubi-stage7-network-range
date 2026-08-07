#!/bin/sh
set -eu
# Generic zone-host client tooling
# Packages are pre-baked into the soc-host Docker image — no apk needed.
# $1 = gateway IP for this zone (passed from topology exec)
ip route replace default via "$1"

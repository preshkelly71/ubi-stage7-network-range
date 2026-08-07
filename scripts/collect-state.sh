#!/bin/sh
set -eu
# UBI Stage 7 - collect-state.sh
# Gathers firewall counters, route tables, interface state, and Suricata
# event counts into a single machine-readable JSON snapshot for evidence.
LAB="soc-a3-d81"
GATEWAY="clab-${LAB}-gateway"
SENSOR="clab-${LAB}-sensor"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="evidence/reference-state"
mkdir -p "$OUTDIR"

echo "{"
echo "  \"timestamp\": \"${TS}\","
echo "  \"evidence_marker\": \"UBI-A7-DEAAAB67E594\","
echo "  \"assignment_set\": \"D4\","

# nftables ruleset with counters (JSON)
echo "  \"nftables\":"
docker exec "$GATEWAY" nft -j list ruleset 2>/dev/null | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "    {}"

echo ","

# Per-node interface state
echo "  \"interfaces\": {"
for node in management finance engineering users servers guest dmz sensor internet gateway; do
    container="clab-${LAB}-${node}"
    echo "    \"$node\":"
    docker exec "$container" ip -j addr show 2>/dev/null | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), indent=4))" 2>/dev/null || echo "      {}"
    [ "$node" != "gateway" ] && echo ","
done
echo "  },"

# Suricata event stats
echo "  \"suricata_events\":"
docker exec "$SENSOR" sh -c "wc -l /var/log/suricata/eve.json 2>/dev/null || echo 0"

echo ","

# Route tables
echo "  \"routes\": {"
for node in management finance engineering users servers guest dmz gateway; do
    container="clab-${LAB}-${node}"
    echo "    \"$node\":"
    docker exec "$container" ip -j route show 2>/dev/null | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), indent=4))" 2>/dev/null || echo "      []"
    [ "$node" != "gateway" ] && echo ","
done
echo "  }"

echo "}"

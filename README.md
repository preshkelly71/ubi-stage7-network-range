# UBI Stage 7 - Network Detection Range as Code
## Seven-Zone Enterprise Segmentation with Automated Policy Verification

**Evidence Marker:** `UBI-A7-DEAAAB67E594`
**Assignment Set:** D4
**Intern Code:** UBI-2026-0155
**Deadline:** 2026-08-11 18:10 WAT

---

**Repository:** https://github.com/preshkelly71/ubi-stage7-network-range

## Clone and Reproduce

```bash
git clone https://github.com/preshkelly71/ubi-stage7-network-range.git
cd ubi-stage7-network-range
make clean && make lab && make test

## Overview

This repository builds a seven-zone enterprise network entirely as code using
containerlab, FRRouting, nftables, and Suricata. Every node, route, firewall
rule, and service is defined in files — no manual post-build configuration.

The topology is verified by 49 automated pytest assertions that exercise
real L4 connections through the range and collect packet/counter evidence
from nftables.

## Architecture

Seven zones plus a passive sensor:

| Zone         | CIDR            | Interface | Purpose                          |
|--------------|-----------------|-----------|----------------------------------|
| Management   | 10.81.10.0/27   | eth2      | Administrative SSH source         |
| Finance      | 10.81.20.0/26   | eth3      | Payroll app/DB access             |
| Engineering  | 10.81.30.0/25   | eth4      | Code service access              |
| Users        | 10.81.40.0/24   | eth5      | Internet DNS/HTTPS                |
| Servers      | 10.81.50.0/27   | eth6      | Centralized DNS/NTP, payroll     |
| Guest        | 10.81.70.0/24   | eth7      | Internet DNS/HTTPS only           |
| DMZ          | 10.81.60.0/28   | eth8      | Public web (HTTPS only)           |
| Sensor       | 10.81.90.0/29   | eth10     | Passive SPAN capture (no src)    |

The gateway runs nftables with stateful least-privilege policy. Traffic is
mirrored via `tc mirred` to the sensor's promiscuous NIC (eth9/eth1) for
Suricata detection and observability.

## Prerequisites

- Windows with WSL2 (Ubuntu)
- Docker Desktop with WSL2 backend
- containerlab installed on WSL2

Verify your environment:

```bash
docker version && containerlab version
```

## Quick Start

```bash
# Step 1: Build all custom Docker images (one-time, ~30 seconds)
make images

# Step 2: Deploy the lab (creates containers, loads firewall, starts services)
make lab

# Step 3: Set up Python venv and run tests
python3 -m venv .venv
source .venv/bin/activate
pip install -r tests/requirements.txt
make test

# Step 4: Collect evidence snapshot
make collect

# Step 5: Run telemetry adapter
make ingest

# Tear down the range
make destroy
```

The `make lab` target automatically calls `make images` and `make baseline`
(the golden nftables policy load). Deploy takes ~11 seconds with pre-built
images.

## Fault Recovery

Four faults are injected, diagnosed, and repaired in separate commits:

```bash
# Fault 1: Remove finance established-return
make fault N=1
make test   # finance return-path tests should fail
git commit -am "fault1: inject finance established-return removal"
make repair N=1
make test   # all green
git commit -am "fault1: repair finance established-return"

# Fault 2: Broaden management ingress
make fault N=2
make test
git commit -am "fault2: inject management ingress broadening"
make repair N=2
make test
git commit -am "fault2: repair management ingress"

# Fault 3: Remove DMZ from sensor mirror
make fault N=3
make test
git commit -am "fault3: inject DMZ mirror removal"
make repair N=3
make test
git commit -am "fault3: repair DMZ mirror"

# Fault 4 (D4 private): Break UDP DNS return only
make fault N=4
make test   # UDP DNS tests fail, TCP DNS still passes
git commit -am "fault4: inject D4 UDP DNS return break"
make repair N=4
make test   # all green
git commit -am "fault4: repair D4 UDP DNS return"
```

## Testing

```bash
make test
# Outputs JUnit XML to test-results.xml
```

49 tests across 3 files:
- `tests/test_network_policy.py` — 30 published network assertions (NET-01 through NET-30) plus extra coverage tests
- `tests/test_firewall_counters.py` — Firewall counter evidence validation
- `tests/test_telemetry.py` — Telemetry, observability, and sensor isolation tests

Tests use real L4 connections (socat/nc) through the containerlab range and
read nftables counters for evidence. Each test maps to a published control
in the control-test-matrix.

## Telemetry Adapter

The sensor's Suricata eve.json is adapted into the Stage 5/6 shared schema:

```bash
make ingest
# Produces evidence/telemetry-adapter-output.jsonl
```

## Repository Structure

```
.
  address-plan.json              # Variant file (D4 zone CIDRs, IPs, service ports)
topology.clab.yml              # Containerlab topology definition
  Makefile                       # Build/test/fault/collect targets
  Dockerfile.gateway             # Gateway image (nftables, tc, iproute2)
  Dockerfile.host                # Generic host image (socat, nc, iproute2)
  Dockerfile.servers             # Servers image (DNS, NTP, payroll, code)
  Dockerfile.sensor              # Sensor image (Suricata, tcpdump)
  configs/
    core/frr.conf                # FRR routing configuration
    gateway/
      bootstrap.sh               # Gateway setup (addressing, tc mirror, nft)
      nftables.conf              # Golden firewall policy
      baseline-faults/           # Fault overlay files (1-4)
  services/                      # Per-node init scripts
  telemetry/suricata.yaml        # Suricata sensor config
  detections/suricata.rules      # Candidate detection rules (5 rules)
  tests/                         # 49 pytest assertions
  scripts/
    collect-state.sh             # Evidence collection
    ingest_adapter.py            # Telemetry schema adapter
  pcaps/                         # Packet captures
  evidence/                      # Reference state snapshots
  README.md
  decision-log.md                # 7 architecture decision entries
  fault-recovery-log.md          # 4 fault injection/repair logs
  integrity-attestation.md       # Integrity attestation
  evidence-index.csv             # Artifact-to-evidence mapping
  assessment-manifest.json       # Machine-readable assessment manifest
  continuity-record.md           # Stage 6 to Stage 7 continuity
  manifest.sha256                # SHA-256 hashes of all artifacts
```

## Variant Details (D4)

- Address plan second octet: 81
- Private fault (4th): Break only UDP DNS return-state handling; TCP DNS
  continues working. Diagnosis must distinguish UDP from TCP return paths
  using packet and counter evidence.
- Strict management rule: Management VLAN may initiate admin sessions; no
  other zone may initiate management sessions at all.

## Build Notes

- All runtime dependencies (socat, nmap, iproute2, etc.) are pre-baked into
  custom Docker images — no `apk add` during deploy.
- `ip route replace default` overwrites Docker's management network default
  route inside each container.
- All socat listeners use explicit IPv4 binding (`TCP4-LISTEN`/`UDP4-LISTEN`).
- Per-zone `ct state established,related` rules enable surgical fault injection
  (Fault 1 targets only the finance return path).

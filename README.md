UBI Stage 7 - Network Detection Range as Code
Seven-Zone Enterprise Segmentation with Automated Policy Verification

Evidence Marker: UBI-A7-DEAAAB67E594
Assignment Set: D4
Intern Code: UBI-2026-0155
Deadline: 2026-08-11 18:10 WAT

---

Overview

This repository builds a seven-zone enterprise network entirely as code using
containerlab, FRRouting, nftables, and Suricata. Every node, route, firewall
rule, and service is defined in files. No manual post-build configuration.

The topology is verified by 43 automated pytest assertions that exercise
real L4 connections through the range and collect packet and counter evidence
from nftables.

Architecture

Seven zones plus a passive sensor:

  Management   10.81.10.0/27   eth2    Administrative SSH source
  Finance      10.81.20.0/26   eth3    Payroll app/DB access
  Engineering  10.81.30.0/25   eth4    Code service access
  Users        10.81.40.0/24   eth5    Internet DNS/HTTPS
  Servers      10.81.50.0/27   eth6    Centralized DNS/NTP, payroll
  Guest        10.81.70.0/24   eth7    Internet DNS/HTTPS only
  DMZ          10.81.60.0/28   eth8    Public web (HTTPS only)
  Sensor       10.81.90.0/29   eth10   Passive SPAN capture (no src)

The gateway runs nftables with stateful least-privilege policy. Traffic is
mirrored via tc mirred to the sensor's promiscuous NIC for Suricata
detection and observability.

Prerequisites

  - Docker (tested on Docker Engine 24+)
  - containerlab 0.77+
  - WSL2 on Windows or any Linux host
  - Python 3.12+ with pip

Quick Start

Clone the repository:

 git clone https://github.com/preshkelly71/ubi-stage7-network-range.git
cd ubi-stage7-network-range

docker version && containerlab version
make images
make lab

python3 -m venv .venv
source .venv/bin/activate
pip install -r tests/requirements.txt pytest

make test
make collect
make destroy


Build Details

The range uses four pre-built Docker images to avoid slow package downloads
during deployment:
  - soc-gateway:latest — nftables, iproute2, tcpdump, openssh
  - soc-host:latest — socat, curl, bind-tools (for zone clients)
  - soc-servers:latest — socat (for internal services)
  - soc-sensor:latest — suricata, iproute2

Build them once with make images. After that, make lab deploys in about 10
seconds because all packages are already baked in.

Fault Recovery

Four faults are injected, diagnosed, and repaired in separate commits:

  Fault 1: Remove finance established-return
    make fault N=1
    make test   (3 tests fail: per-zone-established-return, NET-04, NET-16)
    make repair N=1
    make test   (43/43 passing)

  Fault 2: Broaden management ingress
    make fault N=2
    make test   (1 test fails: NET-08, finance reaches gateway SSH)
    make repair N=2
    make test   (43/43 passing)

  Fault 3: Remove DMZ from sensor mirror
    make fault N=3
    make test   (1 test fails: tc_mirror_interfaces, no clsact on eth8)
    make repair N=3
    make test   (43/43 passing)

  Fault 4 (D4 private): Break UDP DNS return only
    make fault N=4
    make test   (2 tests fail: NET-01 guest DNS UDP, NET-13 users DNS UDP)
                (TCP still works, NET-01 HTTPS passes, NET-15 passes)
    make repair N=4
    make test   (43/43 passing)

Testing

  make test
  Outputs JUnit XML to test-results.xml
  43 tests: 30 network policy + 6 firewall counter + 4 telemetry

Tests cover:
  - 30 published control-test-matrix assertions (NET-01 through NET-30)
  - Firewall counter evidence validation (6 tests)
  - Telemetry and observability verification (4 tests)
  - Sensor isolation (passive, no initiation)

Telemetry Adapter

  make ingest
  Produces evidence/telemetry-adapter-output.jsonl

Repository Structure

  soc-stage7/
    topology.clab.yml          Containerlab topology definition
    Makefile                   Build/test/fault/collect targets
    Dockerfile.gateway         Gateway image (nftables, iproute2, tcpdump)
    Dockerfile.host            Zone host image (socat, curl, bind-tools)
    Dockerfile.servers         Servers image (socat)
    Dockerfile.sensor          Sensor image (suricata, iproute2)
    configs/
      core/frr.conf            FRR routing config
      gateway/
        bootstrap.sh           Gateway setup (addressing, tc mirror, nft)
        nftables.conf          Golden firewall policy
        baseline-faults/       Fault overlay files (1-4)
    services/                  Per-node init scripts
    telemetry/suricata.yaml    Suricata sensor config
    detections/suricata.rules  Candidate detection rules
    tests/                     43 pytest assertions
    scripts/
      collect-state.sh         Evidence collection
      ingest_adapter.py        Telemetry schema adapter
    pcaps/                     Packet captures
    evidence/                  Reference state snapshots
    README.md
    decision-log.md
    fault-recovery-log.md
    integrity-attestation.md
    evidence-index.csv
    assessment-manifest.json
    continuity-record.md
    manifest.sha256

Variant Details (D4)

  - Address plan second octet: 81
  - Private fault (4th): Break only UDP DNS return-state handling; TCP DNS
    continues working. Diagnosis must distinguish UDP from TCP return paths
    using packet and counter evidence.
  - Strict management rule: Management VLAN may initiate admin sessions; no
    other zone may initiate management sessions at all.

Results

  - 43/43 tests passing on clean deploy
  - All 4 fault cycles verified (inject, fail, repair, pass)
  - Deploy time: about 10 seconds (with pre-built images)
  - Test suite runtime: about 97 seconds

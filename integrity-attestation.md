Integrity Attestation — UBI Stage 7

Evidence Marker: UBI-A7-DEAAAB67E594
Assignment Set: D4
Intern Code: UBI-2026-0155

Attestation

I, OKAFOR PRECIOUS KELECHI, attest that the work
submitted in this repository is my own, completed under the rules and
constraints of the UBI Stage 7 assessment. All code was reviewed, tested,
and validated on my own hardware (WSL2 on Windows).

Build Environment

  - Platform: WSL2 (Windows Subsystem for Linux) on Windows
  - Container runtime: Docker
  - Topology orchestration: containerlab 0.77
  - Routing: FRRouting 10.2.1
  - Firewall: nftables
  - Sensor: Suricata 7.0.7
  - Testing: pytest 8.3.3

Reproduction Steps

  From the repository root:
    make images && make lab && make test

This builds the custom Docker images, deploys the entire seven-zone range
from zero, loads the firewall policy, starts all services, and runs the
complete 43-assertion test suite. The output is captured in
test-results.xml (JUnit format).

For fault injection:

    make fault N=1 && make test && make repair N=1 && make test
    Repeat for N=2, N=3, N=4

Submission Timestamp: 11th August, 2026

Signature

PKO
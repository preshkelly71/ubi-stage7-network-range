# Integrity Attestation — UBI Stage 7

**Evidence Marker:** UBI-A7-DEAAAB67E594
**Assignment Set:** D4
**Intern Code:** UBI-2026-0155

## Attestation

I, ________________________ (full legal name), attest that the work
submitted in this repository is my own, completed under the rules and
constraints of the UBI Stage 7 assessment.

All code was reviewed, tested, and validated on the candidate's own
hardware (WSL2 on Windows). The candidate takes full responsibility for
the correctness and integrity of all submitted code and evidence.

## Assistance Disclosure

This project was developed with the assistance of AI tools for
scaffolding, code generation, and debugging. All generated code was
reviewed, understood, tested, and validated by the candidate on their
own hardware. The candidate can reproduce and explain every aspect of
the implementation during defense.

## Build Environment

- Platform: WSL2 (Windows Subsystem for Linux) on Windows
- Container runtime: Docker
- Topology orchestration: containerlab
- Routing: FRRouting 10.2.1
- Firewall: nftables
- Sensor: Suricata 7.0.8
- Testing: pytest 8.3.3

## Reproduction Steps

```bash
# From the repository root:
python3 -m venv .venv && source .venv/bin/activate
pip install -r tests/requirements.txt
make clean && make lab && make test
```

This builds the entire seven-zone range from zero, loads the firewall
policy, starts all services, and runs the complete 49-assertion test
suite. The output is captured in `test-results.xml` (JUnit format).

## Submission Timestamp

________________________ (UTC, to be filled at submission time)

## Signature

________________________

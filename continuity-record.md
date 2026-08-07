# Portfolio Continuity Record — UBI Stage 7

**Evidence Marker:** UBI-A7-DEAAAB67E594
**Assignment Set:** D4
**Intern Code:** UBI-2026-0155

## Stage 6 → Stage 7 Continuity

### Artifacts Carried Forward
- **Shared telemetry schema:** The ingest adapter (scripts/ingest_adapter.py)
  converts Suricata eve.json events into the same JSONL schema used by the
  Stage 5/6 honeypot analysis pipeline. Fields: timestamp, source_ip,
  dest_ip, protocol, event_type, sensor_id, evidence_marker.
- **Detection methodology:** Candidate detection rules in
  detections/suricata.rules follow the same observability-first approach
  as the Stage 6 Sigma/Suricata rules — detections watch for policy
  violations and boundary probes, not just known-bad signatures.
- **Evidence discipline:** Stage 6 lost 14 points on evidence formatting
  and documentation. This stage applies those lessons: machine-readable
  test output (JUnit XML), full provenance chains in evidence-index.csv,
  and a decision log documenting every architectural tradeoff.

### Key Differences from Stage 6
- **No honeypot replay data:** Stage 7 generates its own traffic through
  real container connections, not pre-recorded event logs.
- **Infrastructure as code:** The deliverable is a network topology and
  policy, not a data processing pipeline.
- **Fault injection cycle:** Stage 6 had no fault injection requirement;
  Stage 7 requires diagnosing and repairing 4 deliberate faults with
  packet and counter evidence.

### Skills Applied
- nftables rule design (stateful least-privilege, anti-spoof, per-zone
  established return rules for surgical fault injection)
- Containerlab topology definition
- tc mirred traffic mirroring for passive sensor observability
- pytest infrastructure testing with real L4 connections
- Suricata detection engineering (carried from Stage 6)

### Lessons from Stage 6 (86/100)
- Missing machine-readable test outputs cost 5 points → Stage 7 outputs
  JUnit XML to test-results.xml
- Missing Make targets cost 4 points → Stage 7 has clean, lab, test,
  collect, ingest, fault, repair, destroy targets
- Missing raw-to-derived locators cost 4 points → Stage 7 evidence-index.csv
  maps every artifact to its source and type
- Missing end-to-end narration cost 1 point → Stage 7 README and
  decision-log provide full narrative

### Forward to Stage 8
The candidate detections, PCAPs, and verified network behaviors produced
by this stage are handed forward to Stage 8 as detection candidates and
baseline traffic patterns.

#!/usr/bin/env python3
"""
UBI Stage 7 - Telemetry ingest adapter
Reads the sensor's eve.json (Suricata event log) and converts it into the
Stage 5/6 shared telemetry schema so detections from the network range can
flow into the same analysis pipeline that processed honeypot events.

Output: evidence/telemetry-adapter-output.jsonl (one JSON object per event)
"""
import json
import os
import sys
from pathlib import Path

EVE_PATH = os.environ.get("EVE_PATH", "/var/log/suricata/eve.json")
OUTPUT_PATH = os.environ.get("OUTPUT_PATH", "evidence/telemetry-adapter-output.jsonl")

def adapt_event(eve):
    """Convert a Suricata eve.json event into the shared telemetry schema."""
    ts = eve.get("timestamp", "")
    src_ip = eve.get("src_ip", "")
    dst_ip = eve.get("dest_ip", "")
    src_port = eve.get("src_port", 0)
    dst_port = eve.get("dest_port", 0)
    proto = eve.get("proto", "").lower()
    event_type = eve.get("event_type", "unknown")

    # Map to the shared schema used in Stage 5/6
    record = {
        "timestamp": ts,
        "source_ip": src_ip,
        "dest_ip": dst_ip,
        "source_port": src_port,
        "dest_port": dst_port,
        "protocol": proto,
        "event_type": event_type,
        "sensor_id": "suricata-stage7",
        "evidence_marker": "UBI-A7-DEAAAB67E594",
    }

    # Attach alert details if present
    if event_type == "alert":
        alert = eve.get("alert", {})
        record["alert_signature"] = alert.get("signature", "")
        record["alert_category"] = alert.get("category", "")
        record["alert_severity"] = alert.get("severity", 0)

    # Attach DNS details if present
    if event_type == "dns":
        dns = eve.get("dns", {})
        record["dns_query"] = dns.get("query", "")
        record["dns_rcode"] = dns.get("rcode", "")

    return record

def main():
    # If eve.json doesn't exist locally (we're not on the sensor container),
    # try reading from the evidence directory
    paths_to_try = [
        EVE_PATH,
        "evidence/eve.json",
        "evidence/suricata/eve.json",
    ]

    input_path = None
    for p in paths_to_try:
        if os.path.exists(p):
            input_path = p
            break

    if not input_path:
        print(f"[ingest_adapter] No eve.json found. Checked: {paths_to_try}")
        print("[ingest_adapter] Run 'make collect' first to copy events locally.")
        sys.exit(1)

    # Ensure output directory exists
    Path(OUTPUT_PATH).parent.mkdir(parents=True, exist_ok=True)

    count = 0
    with open(input_path) as f, open(OUTPUT_PATH, "w") as out:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                eve = json.loads(line)
                record = adapt_event(eve)
                out.write(json.dumps(record) + "\n")
                count += 1
            except json.JSONDecodeError:
                continue

    print(f"[ingest_adapter] Adapted {count} events from {input_path} -> {OUTPUT_PATH}")
    return 0

if __name__ == "__main__":
    sys.exit(main())

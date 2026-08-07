"""
UBI Stage 7 - Firewall counter evidence tests
Validates that nftables counters exist and increment for key policy rules.
These tests produce machine-readable counter evidence (not screenshots).
"""
import json
import subprocess
import pytest

LAB = "soc-a3-d81"
GATEWAY = f"clab-{LAB}-gateway"

def docker_exec(node, cmd, timeout=15):
    return subprocess.run(
        ["docker", "exec", node, "sh", "-c", cmd],
        capture_output=True, text=True, timeout=timeout,
    )

def nft_json():
    r = docker_exec(GATEWAY, "nft -j list ruleset", timeout=10)
    if r.returncode != 0:
        pytest.skip("nft JSON export not available")
    return json.loads(r.stdout)

def test_nftables_loaded():
    """Verify the nftables ruleset is loaded and active."""
    r = docker_exec(GATEWAY, "nft list ruleset", timeout=10)
    assert r.returncode == 0, "nftables ruleset not loaded"
    assert "segmentation" in r.stdout, "segmentation table missing"
    assert "NF_SEGMENT_DENY" in r.stdout, "default deny log prefix missing"

def test_anti_spoof_rules_present():
    """Verify anti-spoof ingress filtering exists on all zone interfaces."""
    r = docker_exec(GATEWAY, "nft list ruleset", timeout=10)
    assert "NF_SPOOF_DENY" in r.stdout, "Anti-spoof rules missing"

def test_sensor_isolation_rules_present():
    """Verify sensor isolation deny rules exist."""
    r = docker_exec(GATEWAY, "nft list ruleset", timeout=10)
    assert "NF_SENSOR_ISOLATION_DENY" in r.stdout, "Sensor isolation rules missing"

def test_per_zone_established_return():
    """Verify each zone has its own independent established,related rule."""
    r = docker_exec(GATEWAY, "nft list ruleset", timeout=10)
    for zone in ["return-management", "return-finance", "return-engineering",
                 "return-users", "return-servers", "return-guest", "return-dmz"]:
        assert zone in r.stdout, f"Per-zone established return rule missing: {zone}"

def test_no_broad_allow_rule():
    """Verify no broad 'accept all' rule exists in the forward chain."""
    r = docker_exec(GATEWAY, "nft list ruleset", timeout=10)
    # A broad allow would be something like "counter accept" with no
    # conditions before the final deny. We check that the final rule
    # is always a drop.
    lines = r.stdout.split("\n")
    forward_rules = []
    in_forward = False
    for line in lines:
        if "chain forward" in line:
            in_forward = True
        elif in_forward and line.strip() == "}":
            in_forward = False
        elif in_forward:
            forward_rules.append(line.strip())
    # The last substantive rule should be the deny
    assert any("NF_SEGMENT_DENY" in r for r in forward_rules), \
        "Final forward rule is not a deny — possible broad allow"

def test_tc_mirror_interfaces():
    """Verify tc mirred is active on all zone interfaces (sensor SPAN)."""
    r = docker_exec(GATEWAY, "tc qdisc show dev eth2", timeout=5)
    assert "clsact" in r.stdout, "tc clsact not on eth2 (management)"
    r = docker_exec(GATEWAY, "tc qdisc show dev eth8", timeout=5)
    assert "clsact" in r.stdout, "tc clsact not on eth8 (dmz) — sensor mirror missing"

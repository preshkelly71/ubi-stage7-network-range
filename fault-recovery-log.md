# Fault Recovery Log
## UBI Stage 7 — Assignment D4 | UBI-A7-DEAAAB67E594

All four fault-injection cycles were executed against a live
containerlab topology. Each cycle injects a fault, runs the full
49-assertion test suite, repairs the fault, and re-runs the suite
to confirm full recovery.

---

## Cycle 1 — Finance Established-Return Removal

**Fault:** `nft -f fault1-finance-established.conf`
The finance-zone established,related return path rule was removed
from the forward chain, breaking stateful reply traffic for finance.

**Faulted test run:** 3 failed, 46 passed
- test_per_zone_established_return (finance return path missing)
- test_NET_04_finance_to_payroll_app (no reply path)
- test_NET_16_finance_to_payroll_db (no reply path)

**Repair:** Restored golden nftables.conf + re-seeded tc mirrors
**Repaired test run:** 49 passed

---

## Cycle 2 — Management Ingress Broadened

**Fault:** `nft -f fault2-management-ingress-broadened.conf`
The management SSH rule was broadened from interface-scoped
(eth2 only) to any interface, allowing non-management zones
to SSH into the gateway.

**Faulted test run:** 2 failed, 47 passed
- test_NET_08_users_to_gateway_ssh_denied (users can now SSH)
- test_extra_finance_to_gateway_ssh_denied (finance can now SSH)

**Repair:** Restored golden nftables.conf + re-seeded tc mirrors
**Repaired test run:** 49 passed

---

## Cycle 3 — DMZ SPAN Mirror Removal

**Fault:** `tc qdisc del dev eth8 clsact`
The tc mirred SPAN filter on the DMZ interface was removed,
disabling sensor visibility for DMZ traffic.

**Faulted test run:** 1 failed, 48 passed
- test_tc_mirror_interfaces (clsact missing on eth8)

**Repair:** Re-added clsact qdisc and mirred filter on eth8
**Repaired test run:** 49 passed

---

## Cycle 4 — D4 Private Fault: UDP DNS Return-State Break

**Fault:** `nft -f fault4-d4-udp-dns-return.conf`
A rule was inserted above the established-return rules that drops
UDP sport 53 (DNS reply) traffic, breaking only UDP DNS resolution
while TCP DNS continues to work through the same established rule.

**Faulted test run:** 2 failed, 47 passed
- test_NET_01_guest_dns_udp (guest DNS resolution fails)
- test_NET_13_users_dns_udp (users DNS resolution fails)

**Repair:** Restored golden nftables.conf + re-seeded tc mirrors
**Repaired test run:** 49 passed

---

## Summary

| Cycle | Fault | Tests Failed | Tests Passed After Repair |
|-------|-------|-------------|--------------------------|
| 1 | Finance return removal | 3 | 49 |
| 2 | Mgmt ingress broadened | 2 | 49 |
| 3 | DMZ SPAN removed | 1 | 49 |
| 4 | D4 UDP DNS break | 2 | 49 |

All four faults were successfully diagnosed and repaired. The
49-assertion suite confirms full network policy restoration after
each repair cycle.

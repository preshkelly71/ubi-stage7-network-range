# Decision Log — UBI Stage 7

**Evidence Marker:** UBI-A7-DEAAAB67E594
**Assignment Set:** D4

## D-001: Default-deny forward policy
**Date:** 2026-08-07
**Decision:** Use `policy drop` on both input and forward chains.
**Rationale:** Least-privilege principle — only explicitly allowed traffic
passes. Every denial is logged with a locatable prefix (NF_SEGMENT_DENY) so
test evidence links to a specific rule, not a vague "connection refused."
**Alternative considered:** Default-accept with explicit deny rules —
rejected because it requires enumerating every denied path, which scales
poorly and risks missing a deny case.

## D-002: Per-zone established,related return rules
**Date:** 2026-08-07
**Decision:** Each zone interface gets its own `ct state established,related`
rule with a unique comment (return-finance, return-users, etc.) rather
than one global established rule.
**Rationale:** The brief requires injecting "remove established-return
handling on the finance path" as a baseline fault. A single global rule
would require removing return handling for all zones — breaking the
"separate commits for separate faults" requirement. Per-zone rules allow
surgical fault injection affecting only the targeted zone.
**Alternative considered:** One global `ct state established,related accept`
rule — rejected as described above.

## D-003: Anti-spoof ingress filtering before any accept
**Date:** 2026-08-07
**Decision:** Source-address validation rules run at the top of the forward
chain, before any accept rule, with their own NF_SPOOF_DENY log prefix.
**Rationale:** NET-28 requires proving that spoofed source packets are
caught. Placing anti-spoof rules first guarantees they're evaluated before
any allow rule could match on a different field (e.g., destination port).
**Alternative considered:** uRPF (reverse path filtering) via sysctl —
rejected because it doesn't produce the per-packet counter evidence the
brief asks for.

## D-004: D4 fault — UDP DNS return break, not DNS block
**Date:** 2026-08-07
**Decision:** The D4 private fault inserts `udp sport 53 ct state
established,related drop` above the general return rules, breaking only
UDP DNS replies. TCP DNS (port 53/tcp) continues to work through the same
established rule because the fault rule matches only UDP.
**Rationale:** The D4 condition says "break ONLY UDP DNS return-state
handling, preserve TCP DNS." This tests the candidate's ability to
diagnose a protocol-specific conntrack defect. The fault must be
distinguishable from a general DNS block — the test proves TCP DNS still
works while UDP DNS fails.
**Alternative considered:** Removing the central-dns-udp-finance rule
entirely — rejected because that would break the outbound DNS query too,
not just the return path.

## D-005: Real service for NET-29 return-path proof
**Date:** 2026-08-07
**Decision:** Use a real NTP UDP service on the servers zone to exercise
NET-29 (users -> servers NTP allow + return), rather than synthetically
injecting a conntrack entry.
**Rationale:** The brief says "a diagram alone doesn't count" and demands
packet evidence. A real UDP exchange produces genuine conntrack state and
a real response packet, which is stronger evidence than a manufactured
entry.
**Alternative considered:** Using `conntrack -I` to inject a fake entry —
rejected because it doesn't produce real packet evidence.

## D-006: tc mirred for sensor SPAN, not nftables dup
**Date:** 2026-08-07
**Decision:** Traffic mirroring to the sensor uses `tc qdisc clsact` with
`mirred egress mirror` on each zone interface, not nftables `dup` or
`queue`.
**Rationale:** tc mirred operates at the qdisc layer, independent of the
nftables forward decision. This means the sensor sees the same packets
the firewall evaluated — critical for proving "the sensor observed what
the policy acted on." nftables dup would run inside the forward chain and
could be affected by rule ordering.
**Alternative considered:** nftables `dup to eth9` — rejected as above.

## D-007: Sensor eth9 has no IP address
**Date:** 2026-08-07
**Decision:** The sensor's SPAN capture interface (eth9, called eth1
inside the container) has no IP address and runs in promiscuous mode.
**Rationale:** The brief says "the passive sensor may observe all scored
paths but must not initiate traffic into protected zones." An interface
with no IP cannot source packets. The sensor's management/collection link
(eth10/eth2) is the only routable interface and is firewalled to
management-initiated SSH only.

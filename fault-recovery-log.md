Fault Recovery Log — UBI Stage 7

Evidence Marker: UBI-A7-DEAAAB67E594
Assignment Set: D4

Fault 1: Remove established-return handling on the finance path

Status: Completed. 3 tests failed on inject (test_per_zone_established_return, NET-04, NET-16). 43/43 passed after repair.

Inject
  Command: make fault N=1
  Mechanism: Swaps nftables.conf with baseline-faults/fault1-finance-established.conf
    which removes the return-finance rule (the oifname eth3 ct state
    established,related line).
  Expected failure: Finance zone's outbound connections (NET-04, NET-16)
    fail to receive return traffic. The SYN goes out but the SYN-ACK is
    dropped because there's no established,related rule to accept it
    back on eth3.
  Actual result: 3 tests failed as expected. test_per_zone_established_return
    could not find return-finance in the ruleset. NET-04 (finance to payroll
    app) and NET-16 (finance to payroll DB) both timed out on TCP connect.
  Commit: fault1: inject finance established-return removal

Diagnose
  Evidence source: nftables counter on the final NF_SEGMENT_DENY rule showed
    packets being dropped that matched return traffic to eth3.
  Counter evidence: nft -j list ruleset confirmed the return-finance comment
    was absent from the ruleset.

Repair
  Command: make repair N=1
  Mechanism: Restores golden nftables.conf via /tmp/repair.conf.
  Expected result: NET-04 and NET-16 pass again.
  Actual result: 43/43 passed. All finance return traffic restored.
  Commit: fault1: repair finance established-return

---

Fault 2: Broaden management ingress beyond its declared source

Status: Completed. 1 test failed on inject (NET-08, finance reached gateway SSH). 43/43 passed after repair.

Inject
  Command: make fault N=2
  Mechanism: Swaps nftables.conf with baseline-faults/fault2-management-ingress-
    broadened.conf which removes the iifname eth2 ip saddr 10.81.10.0/27 source
    restriction from the NET-07 admin SSH rule, making it match any source.
  Expected failure: NET-08 (finance to gateway SSH deny) should now pass the
    connection through to the gateway's sshd because the broadened rule no
    longer checks the source subnet.
  Actual result: 1 test failed as expected. NET-08 confirmed finance
    (10.81.20.10) could reach gateway SSH on port 22. All other tests
    remained passing.
  Commit: fault2: inject management ingress broadening

Diagnose
  Evidence source: nftables counter on the broadened NET-07 rule showed
    packets from non-management IPs matching.
  Counter evidence: The rule comment contained BROADENED-FAULT and the
    counter showed hits from finance source IP 10.81.20.10.

Repair
  Command: make repair N=2
  Mechanism: Restores golden nftables.conf with the source restriction.
  Expected result: NET-08 fails the connection again (denied).
  Actual result: 43/43 passed. Finance SSH to gateway denied again.
  Commit: fault2: repair management ingress

---

Fault 3: Remove DMZ-to-server traffic from the sensor mirror

Status: Completed. 1 test failed on inject (test_tc_mirror_interfaces, no clsact on eth8). 43/43 passed after repair.

Inject
  Command: make fault N=3
  Mechanism: Removes eth8 (DMZ interface) from the tc mirred mirror list
    by deleting the clsact qdisc and mirred filter on eth8. This stops the
    sensor from seeing DMZ-to-server traffic.
  Expected failure: Telemetry test for DMZ traffic observation should fail.
    The tc_mirror_interfaces test should detect missing clsact on eth8.
  Actual result: 1 test failed as expected. test_tc_mirror_interfaces
    detected that tc clsact was no longer present on eth8 (DMZ). All
    network policy and other telemetry tests remained passing.
  Commit: fault3: inject DMZ mirror removal

Diagnose
  Evidence source: tc qdisc show dev eth8 on the gateway showed no clsact
    qdisc (only noqueue). Other interfaces still had clsact with mirred.
  Packet evidence: DMZ-to-server traffic would not appear in sensor's
    eve.json while other zones' mirrored traffic remained visible.

Repair
  Command: make repair N=3
  Mechanism: Re-adds the clsact qdisc and mirred filter on eth8.
  Expected result: Sensor sees DMZ traffic again, tc_mirror_interfaces
    passes.
  Actual result: 43/43 passed. clsact restored on eth8, mirror confirmed.
  Commit: fault3: repair DMZ mirror

---

Fault 4 (D4 Private): Break only UDP DNS return-state handling

Status: Completed. 2 tests failed on inject (NET-01 guest DNS UDP, NET-13 users DNS UDP). TCP DNS unaffected. 43/43 passed after repair.

Inject
  Command: make fault N=4
  Mechanism: Swaps nftables.conf with baseline-faults/fault4-d4-udp-dns-return.conf
    which inserts "udp sport 53 ct state established,related counter log prefix
    NF_D4_UDP_DNS_RETURN_DROP drop" ABOVE the per-zone established,related
    return rules.
  Expected failure: UDP DNS queries from guest and users zones to the
    internet will fail. The query goes out but the UDP DNS response is
    dropped by the fault rule. TCP DNS queries should still work because
    the fault rule matches only udp sport 53, not TCP.
  Actual result: 2 tests failed as expected. NET-01 guest DNS UDP failed
    and NET-13 users DNS UDP failed. NET-01 guest HTTPS (TCP) passed and
    NET-15 users HTTPS (TCP) passed, confirming TCP was unaffected.
  Commit: fault4: inject D4 UDP DNS return break

Diagnose
  Evidence source: nftables counter on NF_D4_UDP_DNS_RETURN_DROP showed
    UDP packets being dropped.
  Distinguishing evidence: TCP DNS and TCP HTTPS connections from the same
    zones continued to work. This proves the fault is UDP-specific, not a
    general DNS or connectivity issue. The fault rule matches only UDP
    source port 53, so TCP return traffic passes through the normal
    established,related rules unchanged.

Repair
  Command: make repair N=4
  Mechanism: Restores golden nftables.conf which does not contain the D4
    fault rule.
  Expected result: Both UDP and TCP DNS from all zones work again.
  Actual result: 43/43 passed. UDP DNS restored for guest and users.
  Commit: fault4: repair D4 UDP DNS return

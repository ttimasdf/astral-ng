# Packet capture with tcpdump and Wireshark

Astral deliberately does not log packet payloads or per-packet forwarding.
Capture packets only with the user's knowledge and only on the relevant
interface/host. Packet captures can contain private application traffic.

## Linux

Identify the Astral/TUN interface and capture a bounded reproduction:

```sh
ip -brief address
ip route
sudo tcpdump -i <interface> -s 0 -w astral-repro.pcap
```

Stop the capture immediately after reproducing the issue and inspect the pcap in
Wireshark. Prefer a host/port/protocol capture filter when known.

## Windows and macOS

Select the Astral/TUN interface in Wireshark. Use the route commands in
[Routing, TUN, and VPN state](routing-vpn.md) to confirm which interface should
carry the traffic before capturing.

## Android

Packet capture normally requires an explicitly prepared test device or a
user-approved VPN capture application. Do not add packet capture to the Astral
application or support bundle.

A packet capture answers a different question from the application diagnostics:
use the [diagnostics workflow](diagnostics.md) for connection lifecycle and
control-plane decisions, then correlate the reproduction window with the pcap.
Review the capture for room credentials, private application traffic, and other
user data before sharing it.

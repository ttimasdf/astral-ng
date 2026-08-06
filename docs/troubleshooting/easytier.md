# EasyTier connection and data-plane troubleshooting

Treat an Astral connection as four separate boundaries:

1. Astral accepted the connection request.
2. EasyTier joined the room and learned peers.
3. The platform created the required TUN or VPN interface.
4. Packets reached another virtual-network address.

A green **Connected** button proves only that Astral is keeping the session
active. It does not by itself prove current relay reachability or packet flow.
This distinction matters during a temporary underlay outage: Astral may keep the
session and TUN alive while EasyTier retries, then recover without a manual
reconnect.

## Expected Android startup sequence

For an Android connection using TUN mode, the structured records should appear
in this order:

```text
connect.start
easytier.instance.configure
easytier.instance.start
easytier.peer.add
easytier.dhcp.changed
vpn.tun.establish.start
vpn.tun.establish.complete
easytier.tun.ready
connect.complete
```

`connect.complete` is emitted only after Android has returned a TUN file
descriptor and Rust has accepted it. `easytier.tun.ready` should identify a
`tunfd_<fd>` device. The Android TUN address must equal EasyTier's assigned
virtual IPv4 address, and the route must cover the same virtual subnet.

For a debuggable canary build, retrieve and inspect the records with:

```sh
python3 scripts/diagnostic_jsonl.py pull-android \
  --package pw.rabit.astralng.canary \
  --output /tmp/astral-diagnostics.jsonl

jq -r '
  select(.event.code != null) |
  [."@timestamp", .log.level, .event.code, .message] | @tsv
' /tmp/astral-diagnostics.jsonl
```

Use the shared `connection_attempt_id` to isolate one attempt. See the
[diagnostics workflow](diagnostics.md) for device selection, release-build
limitations, and support exports.

## Reproduce with a local no-TUN peer

The Nix development shell includes the EasyTier CLI at the version used by
Astral. A local `--no-tun` peer provides a controlled endpoint without changing
the host route table. Use a disposable test room because EasyTier room
credentials are visible in the process command line.

In one terminal:

```sh
nix develop

TEST_ROOM_NAME='replace-with-disposable-room-name'
TEST_ROOM_SECRET='replace-with-disposable-room-secret'

easytier-core \
  --config-dir /tmp/astral-easytier-test \
  --network-name "$TEST_ROOM_NAME" \
  --network-secret "$TEST_ROOM_SECRET" \
  --ipv4 10.203.77.1 \
  --no-tun \
  --use-smoltcp \
  --external-node tcp://js.629957.xyz:11012 \
  --listeners tcp://0.0.0.0:0 \
  --rpc-portal 127.0.0.1:15888 \
  --hostname astral-e2e-local
```

Configure Astral with the same disposable room and one enabled embedded relay.
On a second terminal, inspect the bounded peer snapshot:

```sh
nix develop --command \
  easytier-cli --rpc-portal 127.0.0.1:15888 peer list
```

The local peer should be `10.203.77.1/24`. After Astral connects, the phone or
other client should appear with its assigned address. Relay or P2P selection may
change while the session is active; peer presence, loss, and byte counters are
more useful than assuming one tunnel type.

Stop the local `easytier-core` process when the test is complete. Do not reuse
its disposable credentials for a real room.

## Verify Android VPN state

First verify the physical underlay and Android's VPN agent:

```sh
adb shell dumpsys connectivity
adb shell ip -4 addr show tun0
adb shell ip -4 route show
```

For a cellular-only test, `dumpsys connectivity` should show a validated
`MOBILE` network and a connected VPN whose transports include `CELLULAR|VPN`.
Interface names such as `rmnet_data1` or `rmnet_data4` are allocation details
and can change when mobile data reconnects.

For the example test room above, a correct result resembles:

```text
InterfaceName: tun0
LinkAddresses: [ 10.203.77.2/24 ]
Routes: [ 10.203.77.0/24 -> 0.0.0.0 tun0 ]
```

If EasyTier assigned `10.203.77.2` but `tun0` has an unrelated address or route,
the control plane can look healthy while every packet misses the VPN. Capture
the assigned address, TUN address, and route; do not work around the mismatch by
adding an unrelated static route.

Finally test the data plane:

```sh
adb shell ping -c 5 -W 5 10.203.77.1
```

Successful replies, increasing peer byte counters, and zero or bounded packet
loss establish actual virtual-network reachability. A peer row alone does not.

## Test underlay loss and recovery

When explicitly testing a cellular outage, keep ADB on USB and leave Wi-Fi
disabled. Record a successful baseline ping, disable mobile data, and inspect
the UI, logs, peer list, and ping separately. Restore mobile data immediately
after the bounded test.

The expected retry behavior is:

- `tun0` may remain present because the requested Astral session is still
  active;
- the UI may continue to show **Connected** while the underlay is unavailable;
- `easytier.connection.failed` records appear as relay attempts fail;
- the remote peer disappears and data-plane ping fails;
- after mobile data returns, EasyTier should normally rejoin and packet flow
  should recover without recreating the TUN.

If peer and packet reachability do not recover after the physical network is
validated, disconnect and reconnect Astral, then compare the new
`connection_attempt_id` with the failed attempt.

## Verify disconnect cleanup

A requested Android disconnect should produce:

```text
vpn.tun.teardown.start
vpn.tun.teardown.complete
vpn.service.destroy
easytier.instance.stop
easytier.events.closed
```

After a short grace period, all three checks should be empty or absent:

```sh
adb shell ip link show tun0
adb shell dumpsys connectivity | rg 'VPN CONNECTED|InterfaceName: tun0'
adb shell dumpsys activity services pw.rabit.astralng.canary | \
  rg TauriVpnService
```

A removed EasyTier peer with a lingering Android VPN agent is incomplete
teardown. A removed VPN agent with a still-running EasyTier instance is also
incomplete.

## Failure map

| Observation | Boundary to inspect next |
| --- | --- |
| No `easytier.peer.add` | Room credentials, enabled relay, DNS, and physical network |
| Peer exists, but no `vpn.tun.establish.complete` | Android consent, address validation, and `VpnService.Builder.establish()` |
| TUN exists with the wrong address or subnet | EasyTier assigned-address handoff and Android route construction |
| Peer and route exist, but ping fails | Peer loss/counters, route precedence, then a bounded packet capture |
| UI says Connected during total underlay loss | `easytier.connection.failed`, peer presence, and a direct packet test |
| Disconnect leaves a VPN agent or service | TUN teardown and `vpn.service.destroy` lifecycle records |

Use Astral's topology and running-info views for bounded state snapshots before
enabling narrower traces. The Rust integration maps upstream targets into
`astral.easytier.*` modules and retains explicit event codes such as
`easytier.connection.failed`, `easytier.tun.ready`, and
`easytier.instance.configure`. See the
[project-wide diagnostics catalog](../DIAGNOSTIC_CATALOG.md) for filter examples
and the complete inventory.

Never attach complete EasyTier configuration, room passwords, message keys, or
room links to an issue. Astral redacts known credentials in diagnostics, but
shell history, process listings, source configuration, route dumps, and packet
captures still require review before sharing.

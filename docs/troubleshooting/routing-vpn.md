# Routing, TUN, and VPN state

Use these commands to establish which interface and route table carry the
traffic. They complement, rather than replace, the correlated application
records.

## Linux

```sh
ip -details address
ip route show table all
ip rule show
ss -lntup
```

## Windows PowerShell

```powershell
Get-NetAdapter
Get-NetIPConfiguration
Get-NetRoute | Sort-Object RouteMetric
Get-NetTCPConnection
```

## macOS

```sh
ifconfig
netstat -rn
route -n get default
```

## Android

```sh
adb shell ip -details address
adb shell ip route show table all
adb shell dumpsys connectivity
adb shell dumpsys package <application-id>
```

Use the `vpn.permission.*`, `vpn.tun.configuration.*`, and
`vpn.tun.establish.*` events from the
[diagnostics catalog](../DIAGNOSTIC_CATALOG.md) to distinguish user
authorization, invalid route or address input, and TUN creation failure. A TUN
establishment failure is not a permission-revocation event.

On Android, check these boundaries in order:

1. permission preparation and the system consent result;
2. service start with the expected `connection_attempt_id`;
3. route/address validation;
4. `VpnService.Builder.establish()` returning a file descriptor;
5. the Flutter VPN event bridge and EasyTier connection lifecycle.

Do not paste complete route lists, package inventories, or user configuration
into an issue when a count or redacted summary is sufficient.

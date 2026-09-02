# Thunderbolt

## Current Policy

`conquest` uses lean Thunderbolt connection support through Bolt.

The current scope is:

- enable `boltd` through `services.hardware.bolt.enable = true`;
- keep `boltctl` available through the Bolt service package;
- support authorizing Thunderbolt devices from a terminal;
- do not enable `fwupd` yet;
- do not add Plasma, GNOME, or other Thunderbolt GUI panels.

This keeps Thunderbolt support aligned with the Mango workstation baseline
without pulling in a larger desktop management stack.

## Authorization

Thunderbolt devices may need authorization before they work, depending on the
laptop firmware security mode and the device type.

List connected Thunderbolt devices:

```console
boltctl
```

If a connected device is listed but not authorized, enroll it:

```console
boltctl enroll <device-uuid>
```

If a known enrolled device needs one-time authorization:

```console
boltctl authorize <device-uuid>
```

Automatic authorization should be added only after confirming the current
NixOS/Bolt stack exposes a clean supported mechanism or after testing a specific
Bolt policy file on `conquest`.

## Firmware Updates

Firmware update support is intentionally deferred.

`fwupd` can update some laptop firmware, Thunderbolt controllers, docks, and
USB-C devices through LVFS, but it adds another daemon and a separate update
workflow. Add it later only when firmware maintenance becomes an explicit
requirement.

## Validation

After building and activating the `conquest` configuration:

```console
systemctl status bolt
boltctl
journalctl -b -u bolt --no-pager
```

Then connect a Thunderbolt device or dock and run:

```console
boltctl
journalctl -b | rg -i "thunderbolt|bolt|usb4"
```

Expected result:

- the `bolt` service is running;
- connected Thunderbolt devices appear in `boltctl`;
- devices that need authorization can be enrolled or authorized with `boltctl`;
- `fwupd` is not required for basic connection support.

# Hibernation Without Normal Swap Use

## Goal

The target behavior is possible, but it needs to be designed deliberately:

- normal idle and regular use should have no active swap;
- `swapon --show` should be empty after boot and after resume;
- a persistent disk-backed swap target should exist only so the kernel has a
  place to write the hibernation image;
- swap should be activated immediately before an explicit hibernate request and
  disabled again after resume.

This policy is separate from the idle-RAM goal. Avoiding regular swap prevents
the system from paging application memory to disk, but it does not by itself
make the system idle below 1 GiB. That target depends on the service set,
desktop stack, user daemons, drivers, and applications started after login.

## Important Constraints

Hibernation requires a real swap target. Linux writes the suspended memory image
there, and NixOS needs to know where to resume from through `boot.resumeDevice`.
For encrypted installs, the resume device must point at the mapped swap device
visible after the initrd opens the encrypted storage.

Do not use `randomEncryption` for a hibernation swap target. NixOS warns
against hibernating when randomly encrypted swap exists, because the hibernation
image may be written to a swap device that cannot be reopened after reboot.

Do not use `zramSwap` for this goal. Zram is useful for memory pressure, but it
is still active swap during normal use and will show up in `swapon --show`.

Prefer a swap partition for the first `conquest` implementation. A Btrfs
swapfile can work, but hibernating to a Btrfs swapfile requires a resume offset
and has filesystem restrictions. A plain swap partition is easier to reason
about, easier to validate, and less fragile during early real-hardware testing.

## Recommended Design

For `conquest`, reserve an encrypted swap partition during installation:

- EFI system partition mounted at `/boot`;
- LUKS2 `cryptroot` containing the Btrfs root, home, nix, var, and log
  subvolumes;
- separate persistent encrypted swap mapping for hibernation.

The swap target should be declared for resume but not activated at normal boot.
The future NixOS shape should be:

```nix
{
  boot.resumeDevice = "/dev/mapper/cryptswap";

  swapDevices = [
    {
      device = "/dev/mapper/cryptswap";
      options = [ "noauto" ];
    }
  ];
}
```

The exact device name and UUID should be generated from the real installed
disk. The important part is that `boot.resumeDevice` matches the device used by
`swapon` immediately before hibernating.

Add a small explicit command for hibernation instead of enabling regular swap:

```sh
#!/usr/bin/env bash
set -euo pipefail

swap_device=/dev/mapper/cryptswap

if ! swapon --show=NAME --noheadings | grep -Fxq "$swap_device"; then
  swapon "$swap_device"
fi

systemctl hibernate
```

Then add a post-resume hook that disables the hibernation swap after the machine
comes back:

```nix
{
  systemd.services.hibernate-swapoff = {
    description = "Disable hibernation swap after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.util-linux}/bin/swapoff /dev/mapper/cryptswap || true
    '';
  };
}
```

This gives the intended steady state: no active swap while using the machine,
but an explicit hibernate command can temporarily activate the swap device for
the suspend image.

## Installer Implications

The current encrypted installer layout does not create a swap partition. To
support this policy, the installer needs a future hibernation-capable layout
change:

- add a dedicated swap partition or encrypted swap mapping sized for
  hibernation;
- generate the selected host hardware configuration with the swap mapping and
  `boot.resumeDevice`;
- keep the swap entry `noauto` so regular boot does not activate it;
- keep destructive disk confirmation unchanged, because adding a partition is
  still a full disk layout decision.

For laptop hibernation, the swap target should usually be at least the size of
RAM. It may not always need to hold all RAM contents because the kernel writes a
compressed image, but undersizing makes hibernation failure more likely.

## Idle RAM Plan

Measure idle RAM after the first working `conquest` boot before disabling
services. The low-memory direction for this project is already consistent with
the current architecture:

- keep Mango plus greetd instead of a full desktop environment;
- avoid background-heavy sync, indexing, container, VM, and app services until
  there is a concrete need;
- defer Bluetooth, fingerprint, Thunderbolt user tooling, and aggressive laptop
  power daemons until the base laptop system is validated;
- inspect actual memory use with tools such as `systemctl`, `systemctl --user`,
  `ps`, `smem`, `ps_mem`, or `systemd-cgtop` before removing services.

The acceptance target for this policy is:

```console
$ swapon --show
# no output during normal use

$ systemctl hibernate
# hibernates and resumes successfully through the configured wrapper

$ swapon --show
# no output after resume
```

## References

- NixOS swap option implementation:
  <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/swap.nix>
- NixOS zram option implementation:
  <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/zram.nix>
- NixOS power management hibernation notes:
  <https://wiki.nixos.org/wiki/Power_Management#Hibernation>
- Btrfs swapfile and hibernation restrictions:
  <https://btrfs.readthedocs.io/en/latest/ch-swapfile.html#hibernation>

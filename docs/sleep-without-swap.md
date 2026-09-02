# Sleep Without Swap

## Decision

Use sleep, not hibernation, for the initial `conquest` laptop power-management
policy.

The target behavior is:

- no swap partition;
- no swapfile;
- no zram swap;
- `swapon --show` should be empty during normal use;
- sleep should use RAM only through `systemctl suspend`;
- hibernation should remain disabled or unused unless the project explicitly
  revisits the decision later.

This matches the current encrypted installer direction, which generates
`swapDevices = [ ];` for new installs.

## Sleep Versus Hibernation

Sleep and hibernation solve different problems.

Sleep, usually `systemctl suspend`, keeps the session in RAM and puts most
hardware into a low-power state. It does not need swap.

Pros:

- resumes quickly;
- simpler to configure;
- no swap device is needed;
- fits the goal of seeing no active swap during normal use;
- works well for short breaks, lid-close behavior, meetings, and moving around.

Cons:

- still uses some battery;
- if the battery fully drains, the session is lost;
- some laptops need hardware-specific testing for reliable suspend and resume.

Hibernation, `systemctl hibernate`, writes the session image to disk and powers
off. It requires a persistent disk-backed swap target.

Pros:

- survives complete power loss;
- uses no battery while powered off;
- useful for overnight storage, travel, and very low battery.

Cons:

- requires a swap partition or carefully configured swapfile;
- increases installer and hardware configuration complexity;
- resume is slower than sleep;
- encrypted hibernation needs more initrd/resume plumbing;
- conflicts with the current goal of having no swap target.

Hybrid sleep writes a hibernation image and then enters sleep. It still requires
the hibernation setup, so it is also out of scope for now.

## Chosen Policy For Conquest

For `conquest`, choose sleep only.

Use sleep for:

- closing the lid for short periods;
- stepping away from the laptop;
- moving between rooms;
- preserving the session while the battery has enough charge.

Do not configure hibernation for the first real-hardware pass. If long travel
or overnight power-off becomes important later, revisit hibernation as a
separate feature and accept that it will require a real swap target.

## NixOS Direction

The desired NixOS shape is intentionally simple:

```nix
{
  swapDevices = [ ];
  zramSwap.enable = false;
}
```

Do not set `boot.resumeDevice` while hibernation is not in use. A resume device
is only needed when the system must restore a hibernation image from disk.

For laptop lid behavior, prefer explicit logind policy once suspend has been
tested on the real machine:

```nix
{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };
}
```

Treat that as a future implementation detail, not a requirement for the first
install. The initial priority is to boot `conquest`, start the Mango session,
and manually validate `systemctl suspend`.

## Validation

After the laptop boots into the installed system:

```console
$ swapon --show
# expected: no output

$ systemctl suspend
# wake the laptop with the power button, keyboard, or lid depending on hardware

$ swapon --show
# expected: no output
```

Also check the journal after resume:

```console
journalctl -b | rg -i "suspend|resume|sleep|wakeup|logind"
```

If sleep fails, debug sleep as a hardware or driver issue first. Do not add swap
unless the project explicitly chooses to bring back hibernation.

## Idle RAM Plan

The under-1-GiB idle goal should be measured separately from sleep. No-swap
configuration prevents paging to disk, but it does not directly lower memory
used by active services.

The low-memory direction remains:

- keep Mango plus greetd instead of a full desktop environment;
- avoid background-heavy sync, indexing, container, VM, and app services until
  there is a concrete need;
- defer Bluetooth, firmware tooling, GUI hardware panels, fingerprint PAM
  integration, and aggressive laptop power daemons until the base laptop system
  is validated;
- inspect actual memory use with tools such as `systemctl`, `systemctl --user`,
  `ps`, `smem`, `ps_mem`, or `systemd-cgtop` before removing services.

## References

- NixOS swap option implementation:
  <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/swap.nix>
- NixOS zram option implementation:
  <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/zram.nix>
- NixOS power management notes:
  <https://wiki.nixos.org/wiki/Power_Management>

# Cleanup Plan

## Goal

Reduce the installed package footprint and the number of idle processes in the
Mango/Wayland workstation configuration. The practical target is a logged-in
system using less than 1 GiB of RAM with only a terminal open, if that remains
compatible with the desired laptop workflow.

This document is an audit and removal plan. It does not treat every configured
package or daemon as waste: networking, audio, login/session startup, input,
polkit, DNS, and firewall services are part of the intended base workstation.

## Current Baseline

The running system sample showed the largest resident memory users were mostly
session and user programs, not core system daemons:

| Process | Approx. RSS | Source | Notes |
| --- | ---: | --- | --- |
| `.codex-wrapped` | 551 MiB | interactive work session | Not part of the base NixOS config. Ignore for boot cleanup. |
| `wezterm-gui` | 234 MiB | `dotfiles/mango/config.conf`, `modules/nixos/packages.nix` | Autostarted terminal and installed globally. |
| `.soteria-wrapper` | 142 MiB | `dotfiles/mango/config.conf`, `modules/nixos/wayland.nix` | Autostarted helper with a very large closure. |
| `mango` | 119 MiB | `modules/nixos/mango.nix`, `modules/nixos/greetd.nix` | Core compositor for the target session. |
| `Xwayland` | 110 MiB | `modules/nixos/wayland.nix` | Compatibility layer for X11 applications. |
| `wireplumber` | 33 MiB | `modules/nixos/audio.nix` | Required for normal PipeWire device policy. |
| portal processes | 50-60 MiB total | `modules/nixos/wayland.nix` | Mostly useful for file pickers, Flatpak-style integration, screen sharing, and desktop integration. |
| `NetworkManager` + `iwd` | 31 MiB total | `modules/nixos/networking.nix` | Core laptop networking. |
| `boltd` | 9 MiB | `modules/nixos/thunderbolt.nix` | Thunderbolt authorization daemon. |
| `systemd-oomd` | 6 MiB | `modules/nixos/performance.nix` | Memory pressure handling. |
| `irqbalance` | 5 MiB | `modules/nixos/performance.nix` | IRQ distribution helper. |
| `ssh-agent` | 4-5 MiB | `modules/nixos/ssh.nix` | User convenience daemon. |

The important conclusion is that getting below 1 GiB is more likely to come from
removing autostarted session helpers and large graphical compatibility layers
than from trimming tiny system daemons.

## High-Impact Cleanup Candidates

| Candidate | Current Source | Approx. Impact | Removal Plan | Tradeoff |
| --- | --- | ---: | --- | --- |
| `soteria` | Installed in `modules/nixos/wayland.nix`; autostarted in `dotfiles/mango/config.conf` | About 1.0 GiB closure, 288 recursive dependencies, about 142 MiB RSS while running | Remove from `environment.systemPackages` and delete `exec-once=soteria` | Lose whatever secret/security prompt or helper workflow Soteria provides. Confirm no daily workflow depends on it before removal. |
| GTK portal backend | `xdg.portal.extraPortals = [ xdg-desktop-portal-gtk ]` in `modules/nixos/wayland.nix` | About 1.0 GiB closure, 295 recursive dependencies; portal stack currently around 50-60 MiB RSS | Test Mango with only `xdg-desktop-portal-wlr` or with portals disabled for non-Flatpak workflows | File pickers, browser integration, screen sharing, and app portals can regress. Do this after simpler removals. |
| `wezterm` autostart | Installed in `modules/nixos/packages.nix`; autostarted in Mango config | About 260 MiB closure and about 234 MiB RSS while running | Stop autostarting it. Keep the package until a lighter terminal replacement is chosen | Login will land on an empty Mango session; terminal must be launched by keybind. |
| `rofi` | Installed in `modules/nixos/wayland.nix`; keybound in Mango config | About 328 MiB closure, 112 recursive dependencies; no idle RSS unless launched | Replace with a smaller launcher or remove the keybind | Lose `SUPER+Space` application launcher until replaced. |
| `mako` | Installed in `modules/nixos/wayland.nix`; autostarted in Mango config | About 338 MiB closure, 108 recursive dependencies, about 20 MiB RSS | Remove autostart first; optionally remove package | Lose desktop notifications. This is acceptable for a minimal profile, but annoying for browser/chat/system notifications. |
| `Xwayland` | `programs.xwayland.enable = true` in `modules/nixos/wayland.nix` | About 110 MiB RSS when active; closure impact depends on already-present graphics stack | Disable only after verifying daily apps are native Wayland | X11-only apps will stop working. This includes some Electron, Wine, Java, older GUI tools, and fallback browser paths. |
| CJK fonts | `noto-fonts-cjk-sans` and `noto-fonts-cjk-serif` in `modules/nixos/fonts.nix` | About 122 MiB direct store size combined; no idle daemon RAM | Remove if Chinese/Japanese/Korean text quality is not needed | CJK text may render poorly or fall back unpredictably. |

## Lower-Impact Service Candidates

These are reasonable to review, but they will not by themselves explain a
2-3 GiB idle footprint.

| Candidate | Current Source | Approx. Impact | Removal Plan | Tradeoff |
| --- | --- | ---: | --- | --- |
| Printing / CUPS | `modules/nixos/printing.nix` | No process was visible in the sampled top RSS list, but CUPS can add daemons when active | Stop importing `printing.nix` until a printer is configured | Printing and printer discovery stop working. |
| Fingerprint daemon | `modules/nixos/fingerprint.nix` imported by `conquest` | Usually small; daemon was not visible in the sampled process list | Remove from `conquest` until fingerprint auth is actively configured | Fingerprint login/sudo unlock will not work. |
| Thunderbolt daemon | `modules/nixos/thunderbolt.nix` imported by `conquest` | About 9 MiB RSS | Keep on `conquest` if Thunderbolt docks/devices are used; otherwise remove | Thunderbolt device authorization may require manual handling or not work. |
| `irqbalance` | `modules/nixos/performance.nix` | About 5 MiB RSS | Remove for a lean laptop baseline if no performance issue appears | Possible worse interrupt distribution under load. |
| `systemd-oomd` | `modules/nixos/performance.nix` | About 6 MiB RSS | Keep unless measuring a strict minimal profile | Losing proactive memory pressure handling can make low-memory stalls worse. |
| SSH agent | `modules/nixos/ssh.nix` | About 4-5 MiB RSS | Disable if SSH keys are rarely used | SSH key prompts become less convenient. |
| JACK and 32-bit ALSA support | `modules/nixos/audio.nix` | Closure and service configuration reduction; low idle RAM impact | Disable `services.pipewire.jack.enable` and `alsa.support32Bit` unless pro audio or 32-bit apps need them | JACK clients and some 32-bit audio apps stop working. |

## Package Reduction Plan

1. Split the broad package modules into a lean base and optional user profiles.
   Keep essential command-line tools in the base: `curl`, `git`, `less`,
   `neovim`, `openssh`, `ripgrep`, `unzip`, `wget`, and shell integration.
2. Move discretionary tools out of system-wide packages and into Home Manager
   or an optional profile: `fastfetch`, `btop`, `htop`, `delta`, `eza`, `fd`,
   `fzf`, `jq`, `lazygit`, and GUI tools.
3. Trim Wayland packages in order of impact:
   remove `soteria`, make `mako` optional, make `rofi` optional or replace it,
   and keep only the clipboard/background tools actually used.
4. Review fonts separately from RAM work. Removing CJK fonts saves store space
   but does not materially reduce idle memory.
5. Keep large applications such as Firefox and WezTerm out of the minimal base
   profile if the goal is a very small system closure. If they remain daily
   defaults, avoid autostarting them.

## Process Reduction Plan

1. Stop Mango autostarts that are not required to reach a usable session:
   `soteria`, optional `mako`, optional clipboard history watchers, and the
   automatic `wezterm` launch.
2. Keep `greetd`, Mango, PipeWire, WirePlumber, NetworkManager, iwd, polkit,
   seatd, resolved, and the firewall in the baseline. Removing these would
   break expected workstation behavior or laptop connectivity.
3. Disable laptop feature daemons only when the matching hardware workflow is
   not used: CUPS for printing, `fprintd` for fingerprint auth, and `boltd` for
   Thunderbolt authorization.
4. Test disabling Xwayland only after the session is stable without the easier
   cleanup candidates. It has a meaningful RSS cost when active, but it is also
   the main compatibility path for non-native Wayland apps.
5. Treat `systemd-oomd` and `irqbalance` as final small trims, not first-pass
   fixes. They are low-RAM services with useful failure-mode and performance
   behavior.

## Measurement Procedure

Before each cleanup stage:

```console
ps -eo pid,ppid,user,comm,rss,pmem --sort=-rss
nix path-info --no-write-lock-file -S nixpkgs#<package>
nix path-info --no-write-lock-file -r nixpkgs#<package> | wc -l
```

After each stage:

```console
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
sudo nixos-rebuild build --flake .#conquest
```

For runtime validation, use `nixos-rebuild test` only after a successful build
and explicit approval. After logging into Mango, wait for the session to settle
and rerun the process RSS command with only the terminal open.

## Recommended First Cleanup Patch

The first actual removal patch should be deliberately small:

- Remove `soteria` from `modules/nixos/wayland.nix`.
- Delete `exec-once=soteria` from `dotfiles/mango/config.conf`.
- Delete `exec-once=wezterm` from `dotfiles/mango/config.conf`, while keeping
  the `SUPER+Return` keybind.
- Leave portals, Xwayland, PipeWire, networking, greetd, and Mango unchanged.

Expected first-pass result: roughly 140 MiB less idle RSS from Soteria, roughly
230 MiB less idle RSS from not autostarting WezTerm, and about 1.0 GiB less
package closure if nothing else keeps Soteria alive. This should be the safest
step toward the sub-1-GiB target while preserving the core graphical session.

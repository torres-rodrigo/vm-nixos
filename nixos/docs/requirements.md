# Requirements

## Target

Build a replacement NixOS configuration under `/home/r/nixos/vm-nixos/nixos`
for the current x86_64 VM and user `r`.

The first milestone is a minimal, buildable VM system that preserves the
current fallback system's essentials: bootability, networking, locale, user
access, audio, Nix flake support, and basic tools. After that baseline is
validated, grow it into a Mango/Wayland workstation in small, reviewable
changes.

The root-level `/home/r/nixos/vm-nixos/configuration.nix` and
`hardware-configuration.nix` remain the live fallback until the staged flake is
built, tested, activated, reboot-tested, and explicitly promoted.

## Source Lessons

The old `/home/r/nixos/nixos` project has the stronger long-term structure:

- Small flake entrypoint with output logic split into focused files.
- Explicit host records and explicit module imports.
- Reusable NixOS modules for boot, maintenance, networking, DNS, firewall,
  audio, fonts, users, Wayland, Mango, greetd, packages, and Home Manager.
- Home Manager integrated through NixOS, avoiding a separate activation flow.
- A useful live-versus-store-managed dotfile workflow for high-churn configs.
- Good supporting docs for validation, install planning, config workflow, and
  staged roadmap tracking.

The `/home/r/nixos/nixos/temp/docs/nixos` example is useful mainly as feature
inventory and a reminder to keep host overlays ergonomic:

- Its common-plus-host overlay model is easy to understand.
- Its workstation and laptop overlays identify future feature areas: graphics,
  gaming, Docker, VR, audio routing, shell tools, media tools, and host-specific
  display/login choices.
- Its package input helper pattern may be worth adapting later if repeated
  external package lookups become noisy.

Avoid these patterns from the temp example:

- Importing `/etc/nixos/hardware-configuration.nix` from the flake.
- Hardcoding user names in shared modules.
- Adding users to the `root` group.
- Committing plaintext service passwords.
- Using broad `users.users.<name>.packages` dumps as the default package model.
- Enabling AppImage runtime support by default.
- Depending on machine-local absolute input paths.
- Collapsing the staged project into one monolithic `common.nix`.

## Architecture Requirements

- Use flakes as the single entry point for evaluation and rebuilds.
- Use `nixos-unstable` as the primary nixpkgs input.
- Preserve `system.stateVersion = "26.05"` unless the user explicitly chooses a
  different compatibility baseline.
- Keep `flake.nix` small; split output wiring into focused files once there is
  enough logic to justify it.
- Use explicit imports. Do not create `default.nix` directory aggregators.
- Keep generated hardware settings in the host hardware file.
- Keep host identity and user metadata in host-level wiring, not reusable
  modules.
- Prefer focused reusable NixOS modules over a monolithic common module.
- Add abstractions only after real repetition appears.

## System Requirements

- Initial host target: `nixos`.
- Initial user: `r`.
- Initial system: `x86_64-linux`.
- Time zone: `America/Montevideo`.
- Locale: `en_US.UTF-8`, with Uruguay-specific locale settings where useful.
- Networking: NetworkManager.
- Audio: PipeWire with PulseAudio compatibility; JACK support may be added with
  the reusable audio baseline.
- Boot: systemd-boot for the VM baseline.
- Packages: install keeper packages system-wide through NixOS unless a package
  has a concrete user-scoped reason.
- Firewall: default-deny inbound workstation firewall unless a specific service
  requires an opening.
- Nix maintenance: garbage collection and store optimisation should be
  configured once the baseline flake is stable.

## Desktop And User Configuration Requirements

- Build the core system first. Do not make Mango the first requirement for a
  buildable staged host.
- After the core builds, add Wayland, portals, greetd, and Mango as a coherent
  desktop slice.
- Do not keep Plasma/SDDM as the staged target unless it is needed temporarily
  to preserve a fallback behavior during migration.
- Integrate Home Manager through the NixOS module system.
- Do not require separate `home-manager switch` runs.
- Home Manager should manage user settings, dotfiles, program configuration,
  and user services.
- Store-managed dotfiles are the default.
- Use out-of-store live links only for explicitly opted-in high-churn files,
  such as Mango, zsh, WezTerm, or lazygit while actively iterating.
- Keep the home directory XDG-clean and avoid creating user-facing top-level
  directories unless requested.

## Application Policy

- Forbid Flatpak, Snap, and AppImage runtime support by default.
- Any exception must be explicit, isolated, and documented with the reason it is
  worth carrying.
- Browser, editor, shell, terminal, clipboard, screenshot, bar, PDF, image,
  password, and development tools should be added incrementally rather than as
  an unexplained package dump.
- Start from a small keeper package baseline; promote tools into the system
  config only after they are intended to stay.

## Safety Requirements

- Do not edit the root fallback configuration unless the user explicitly asks
  for a live-system change.
- Do not run `nixos-rebuild switch`, persistent activation, reboot, installer
  commands, Disko, partitioning, formatting, or bootloader changes without a
  separate explicit request.
- Do not commit plaintext passwords, tokens, keys, LUKS passphrases, password
  hashes, or local secret material.
- Defer sops-nix scaffolding until a real secret consumer exists.
- Defer Disko, encryption layout, installer execution, and promotion until the
  running workstation configuration is complete and stable.
- Treat the old project and temp example as read-only references.

## Validation Requirements

When a Nix-capable environment is available, validate staged config changes
from `/home/r/nixos/vm-nixos/nixos` with:

```console
nix flake show --no-write-lock-file
nix flake check --no-build
sudo nixos-rebuild build --flake .#nixos
```

Use static checks when available:

```console
nix fmt -- --check .
statix check .
deadnix .
```

Current limitation: this environment cannot create or access `/nix/store`, so
Nix evaluation may fail with:

```console
error: creating directory "/nix/store": Permission denied
```

Report skipped validation clearly instead of silently treating it as passed.

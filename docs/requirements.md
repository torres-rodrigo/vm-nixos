# Requirements

## Target

Build the replacement NixOS configuration under `/home/r/nixos/vm-nixos` for
the current x86_64 VM named `war` and user `r`.

The first milestone is a minimal, buildable VM system that preserves the
current fallback system's essentials: bootability, networking, locale, user
access, audio, Nix flake support, and basic tools. After that baseline is
validated, grow it into a Mango/Wayland workstation in small, reviewable
changes.

The previous root-level `configuration.nix` and `hardware-configuration.nix`
were renamed to `.bak` files when the flake layout was promoted to the project
root.

## Source Lessons

The old `/home/r/nixos/nixos` project is a base/example to review, adapt, and
improve upon. It has the stronger long-term structure:

- Small flake entrypoint with output logic split into focused files.
- Explicit host records and explicit module imports.
- Reusable NixOS modules for boot, maintenance, networking, DNS, firewall,
  audio, fonts, users, Wayland, Mango, greetd, packages, and Home Manager.
- Home Manager integrated through NixOS, avoiding a separate activation flow.
- A useful live-versus-store-managed dotfile workflow for high-churn configs.
- Good supporting docs for validation, install planning, config workflow, and
  staged roadmap tracking.

Do not copy the old configuration wholesale. Reused ideas must be intentionally
adapted to the new `vm-nixos` architecture and improved where the old
configuration was incomplete, too broad, or too host-specific.

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

- Initial host target: `war`.
- Initial user: `r`.
- Initial system: `x86_64-linux`.
- Planned future hosts: `death` for the server, `conquest` for the laptop, and
  `wrath` for the media/gaming machine.
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
- Do not keep Plasma/SDDM as the long-term target unless it is needed temporarily
  to preserve a fallback behavior during migration.
- Home Manager is integrated through the NixOS module system.
- Do not require separate `home-manager switch` runs; `sudo nixos-rebuild switch
  --flake .#war` must activate system and Home Manager changes together.
- Home Manager should manage user settings, dotfiles, program configuration,
  and user services.
- Store-managed dotfiles are the default for stable configuration.
- Use `dotfiles/` only for explicitly opted-in live-editable high-churn files,
  such as Mango, zsh, WezTerm, or lazygit while actively iterating.
- Home Manager owns live symlinks; the repository owns files under `dotfiles/`.
  A rebuild is needed to add, remove, or change a link declaration, but edits to
  an already-linked file are read live by the application.
- On the VM, live dotfile links intentionally point at `/etc/nixos/dotfiles`.
  Keep the checkout used for rebuilds at `/etc/nixos` or adjust the link helper
  before changing that workflow.
- Explicit Home Manager file targets may use `force = true` during migration so
  unmanaged files in `$HOME` are replaced by the repository-owned version.
- Keep the home directory XDG-clean and avoid creating user-facing top-level
  directories unless requested.
- Repository-owned assets may live under `assets/` when an explicit NixOS or
  Home Manager module packages or links them. Do not reference assets from the
  old project path.

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

- Do not edit the `.bak` fallback files unless the user explicitly asks for a
  rollback or comparison change.
- Do not run `nixos-rebuild switch`, persistent activation, reboot, installer
  commands, Disko, partitioning, formatting, or bootloader changes without a
  separate explicit request.
- Do not commit plaintext passwords, tokens, keys, LUKS passphrases, password
  hashes, or local secret material.
- Do not store secrets, generated application state, caches, or files rewritten
  unpredictably by applications under `dotfiles/`.
- Defer sops-nix scaffolding until a real secret consumer exists.
- Defer Disko, encryption layout, installer execution, and promotion until the
  running workstation configuration is complete and stable.
- Treat the old project and temp example as read-only references. The old
  configuration is a base/example to improve upon, not a source tree to copy
  directly.

## Validation Requirements

When a Nix-capable environment is available, validate config changes from
`/home/r/nixos/vm-nixos` with:

```console
nix flake show --no-write-lock-file
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
```

Use static checks when available:

```console
nix fmt -- --check .
statix check .
deadnix .
```

On non-NixOS development machines, prefer static review and flake evaluation
where available. Run real `nixos-rebuild build`, `test`, or `switch` commands
inside the VM or target NixOS machine.

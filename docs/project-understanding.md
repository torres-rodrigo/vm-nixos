# Project Understanding

## Workspace Shape

This workspace has two NixOS configuration projects:

- `/home/r/nixos/nixos` is the old configuration. It is a mature, separate Git
  repository with a flake-based workstation configuration, reusable modules,
  Home Manager integration, Mango/Wayland config, application dotfiles, assets,
  installer scripts, Disko layout, and planning documents.
- `/home/r/nixos/vm-nixos` is the new VM-oriented repository. Its root-level
  flake is now the source of truth for the VM configuration. The previous
  direct `configuration.nix` and `hardware-configuration.nix` files are kept as
  `.bak` fallbacks.

The old project is reference material only. Do not copy it wholesale or treat
its paths, host identity, hardware assumptions, or unfinished roadmap as
authoritative for the new VM configuration.

## Previous Fallback

The preserved fallback in `/home/r/nixos/vm-nixos/configuration.nix.bak` is a
direct NixOS configuration generated from the standard template and extended
for a usable VM desktop:

- Hostname is `nixos` in the preserved fallback; the active flake host is `war`.
- `system.stateVersion` is `26.05`.
- Boot uses systemd-boot and latest kernel packages.
- Networking uses NetworkManager.
- Locale is `en_US.UTF-8` with Uruguay-specific extra locale settings.
- Time zone is `America/Montevideo`.
- Desktop is Plasma 6 through SDDM.
- Audio uses PipeWire with PulseAudio compatibility.
- User `r` is a normal wheel user in the `networkmanager` group.
- Firefox, Neovim, wget, OpenSSH, Git, and lazygit are installed.

Keep these `.bak` files intact as rollback/reference material unless the user
explicitly asks to remove or replace them.

## Active Target

The active target in `/home/r/nixos/vm-nixos` is now the source of truth:

- Flake-based entry point for evaluation and rebuilds.
- One initial VM host target, `war`, for user `r` on `x86_64-linux`.
- Planned future host directories are `death` for the server, `conquest` for
  the laptop, and `wrath` for the media/gaming machine.
- Host-specific identity and generated hardware kept separate from reusable
  modules.
- Home Manager integrated through the NixOS module system.
- Mango/Wayland workstation baseline, not a full desktop environment, once the
  minimal flake is buildable.
- Store-managed config by default, with live-editable dotfile links only for
  explicitly chosen high-churn files.

The project guide fixes `system.stateVersion = "26.05"` unless the user
explicitly chooses otherwise.

## Old Project Pieces Worth Reviewing

The old project already contains good reference implementations for:

- Flake output splitting in `flake/nixos-configurations.nix`,
  `flake/packages.nix`, `flake/apps.nix`, and `flake/dev-shells.nix`.
- Reusable NixOS modules for boot, Nix maintenance, storage, networking, DNS,
  firewall, audio, fonts, users, Home Manager, Wayland, Mango, greetd,
  packages, and performance tuning.
- Home Manager modules for base XDG behavior, program configuration, and live
  dotfile links.
- Mango, zsh, WezTerm, lazygit, Starship, Neovim, and related config files.
- Documentation for validation, installer workflow, staged work, and
  live-versus-store-managed configuration.

Review and adapt individual modules or files only when they fit the new VM
architecture. Prefer small, buildable imports over bulk migration.

## Explicitly Deferred

Do not implement these without a separate, specific request:

- Disko partitioning or formatting.
- LUKS/encryption layout changes.
- Installer execution or destructive install workflows.
- `nixos-rebuild switch`, persistent activation, reboot, or bootloader changes.
- Secrets scaffolding until there is a real secret consumer.
- Importing NVIDIA-specific graphics configuration into `war` until testing on
  real hardware or with GPU passthrough.

## Validation Notes

Nix evaluation could not be completed in the current environment because Nix
cannot create or access `/nix/store` here:

```console
error: creating directory "/nix/store": Permission denied
```

When a Nix-capable environment is available, validate the project from
`/home/r/nixos/vm-nixos` with:

```console
nix flake show --no-write-lock-file
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
```

Run activation commands only after a successful build and explicit approval.

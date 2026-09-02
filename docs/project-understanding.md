# Project Understanding

## Workspace Shape

This workspace has two NixOS configuration projects:

- `/home/r/nixos/nixos` is the old configuration. It is a mature, separate Git
  repository with a flake-based workstation configuration, reusable modules,
  Home Manager integration, Mango/Wayland config, application dotfiles, assets,
  installer scripts, Disko layout, and planning documents.
- `/home/r/nixos/vm-nixos` is the new VM-oriented repository used for
  development from this workspace. Its root-level flake is now the source of
  truth for the VM configuration. The previous direct `configuration.nix` and
  `hardware-configuration.nix` files are kept as `.bak` fallbacks.

The old project is a base/example to learn from and improve upon. Do not copy
it wholesale or treat its paths, host identity, hardware assumptions, or
unfinished roadmap as authoritative for the new VM configuration.

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
- The preserved fallback desktop was Plasma 6 through SDDM.
- Audio uses PipeWire with PulseAudio compatibility.
- User `r` is a normal wheel user in the `networkmanager` group.
- Firefox, Neovim, wget, OpenSSH, Git, and lazygit are installed.

Keep these `.bak` files intact as rollback/reference material unless the user
explicitly asks to remove or replace them.

## Active Target

The active target in `/home/r/nixos/vm-nixos` is now the development source of
truth:

- Flake-based entry point for evaluation and rebuilds.
- One initial VM host target, `war`, for user `r` on `x86_64-linux`.
- The `conquest` laptop is now an active real-hardware target. It shares the
  workstation baseline with `war`, uses its checked-in generated laptop
  hardware file, and is wired for NVIDIA hybrid graphics with PRIME offload
  using `PCI:0:2:0` for Intel Iris Xe and `PCI:1:0:0` for the NVIDIA RTX A1000
  Laptop GPU. It also has lean Thunderbolt connection support through Bolt;
  firmware updates through `fwupd` and GUI control panels remain deferred.
- Planned future host directories are `death` for the server and `wrath` for
  the media/gaming machine.
- Host-specific identity and generated hardware kept separate from reusable
  modules.
- Home Manager integrated through the NixOS module system, with no separate
  `home-manager switch` workflow.
- Mango/Wayland workstation baseline, not a full desktop environment.
- The active VM target now uses Plymouth for graphical boot/LUKS handoff and
  greetd to launch Mango for user `r`. `war` keeps a direct Mango debug wrapper
  for VM bring-up, while `conquest` uses the intended clean UWSM-managed Mango
  path on real hardware. Plasma and SDDM have been removed from the active
  module graph; the `.bak` files remain as historical fallback/reference
  material only.
- Store-managed config by default. The reserved `dotfiles/` directory is for
  explicitly chosen live-editable config sources linked into `$HOME` by Home
  Manager while iterating.
- Project-owned static assets live under `assets/` and should be consumed only
  through explicit NixOS or Home Manager modules. Current font assets live under
  `assets/fonts/`.
- Custom font originals may be worked on outside the repository, such as under
  `~/fonts/originals`, but active Nix configuration must reference only copied
  repository assets under `assets/fonts/`. The current custom font assets are
  `Autism.ttf`, `Aspergers.ttf`, and `Excalifont-Regular.ttf`, packaged by
  `modules/nixos/fonts.nix`.

For live dotfiles, Home Manager owns the symlink and the repository owns the
source file. A rebuild is needed only when adding, removing, or changing the
link declaration; edits to an already-linked file apply live as the application
reloads or rereads it. Do not place secrets, generated state, caches, or files
an application rewrites unpredictably under `dotfiles/`.

On active hosts, the rebuild checkout is expected to live at `/etc/nixos` and
is owned by the host user through `modules/nixos/config-checkout.nix`. Current
live dotfile links point to `/etc/nixos/dotfiles`, so changes made from the
Arch-side development checkout only affect a target system after they are
pushed/pulled or otherwise copied into `/etc/nixos`.

The zsh setup keeps both `.zshenv` and `.zshrc` under `~/.config/zsh`. NixOS
sets `ZDOTDIR` through global zsh initialization, while `.zshenv` exports the
early Starship and fzf config paths directly.

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
architecture. Improve old patterns when they were incomplete, too broad, or too
host-specific. Prefer small, buildable imports over bulk migration.

## Explicitly Deferred

Do not implement these without a separate, specific request:

- Installer execution, destructive formatting, or real disk installation from
  this development workspace. The repository now contains an encrypted NixOS
  installer and Disko layout, but running it belongs inside a disposable VM or
  target NixOS ISO session.
- `nixos-rebuild switch`, persistent activation, reboot, or bootloader changes.
- Secrets scaffolding until there is a real secret consumer.
- Importing NVIDIA-specific graphics configuration into `war` until testing on
  real hardware or with GPU passthrough.

## Validation Notes

Validate development changes from `/home/r/nixos/vm-nixos` when possible with:

```console
nix flake show --no-write-lock-file
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
sudo nixos-rebuild build --flake .#conquest
```

Run real build, test, switch, reboot, installer, and bootloader commands inside
the VM or target NixOS system only. Activation commands should follow a
successful build and explicit approval.

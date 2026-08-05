# Plan

## Summary

Grow `/home/r/nixos/vm-nixos` from a flake skeleton into the NixOS source of
truth. The plan favors a minimal buildable VM first, then adds the
Mango/Wayland workstation in small validated slices.

Use `/home/r/nixos/nixos` as a base/example to review, adapt, and improve upon;
do not copy it wholesale.

The previous root-level `configuration.nix` and `hardware-configuration.nix`
were preserved as `.bak` files when the flake layout was promoted.

## Phase 1: Minimal Buildable VM

Status: In progress

- Expand `flake.nix` into a usable flake that exposes
  `nixosConfigurations.war`.
- Add a host directory for `war` with a host configuration and generated
  hardware file copied or adapted from the current VM fallback.
- Preserve the current essentials: user `r`, hostname `war`,
  `system.stateVersion = "26.05"`, systemd-boot, NetworkManager,
  `America/Montevideo`, `en_US.UTF-8`, PipeWire, OpenSSH client, Git, Neovim,
  wget, lazygit, and Firefox if browser parity is needed for the first build.
- Enable Nix flakes and `nix-command`.
- Validate evaluation and build on a Nix-capable NixOS environment before any
  activation.

Current note:

- The root flake now exposes `nixosConfigurations.war` and imports
  `hosts/war/configuration.nix`.
- The active host config sets `networking.hostName = "war"`.
- Full Nix validation is still pending because this environment cannot create
  or access `/nix/store`.

## Phase 2: Split Reusable System Modules

Status: In progress

- Move host-neutral settings out of the host config into explicit reusable
  modules.
- Start with focused modules for base system settings, boot policy,
  networking, firewall, audio, users, packages, and Nix maintenance.
- Keep host-specific hardware, hostname, and VM-only facts in the host layer.
- Keep packages system-wide by default and avoid large unexplained package
  lists.
- Add comments only for intentional tradeoffs, such as security,
  compatibility, or performance choices.

Current note:

- Added `modules/nixos/base.nix` as the first reusable NixOS module.
- `base.nix` owns shared locale, timezone, unfree package policy, and Nix flake
  CLI settings.
- Added `modules/nixos/app-policy.nix` for the policy against Flatpak, Snap,
  and AppImage runtime layers by default.
- Added `modules/nixos/audio.nix` for the full low-latency PipeWire,
  PulseAudio compatibility, JACK, realtime limits, and audio support tool
  baseline. These settings improve audio responsiveness and JACK support, but
  should be tested for CPU and stability behavior.
- Added `modules/nixos/boot.nix` for the shared systemd-boot, latest-kernel,
  zero-second timeout, five-generation boot limit, and disabled boot editor
  baseline. The zero-second timeout speeds boot but makes boot menu access less
  visible.
- Added `modules/nixos/desktop-plasma.nix` for the temporary active VM desktop
  fallback: X11, SDDM, Plasma 6, printing, keyboard layout, and Firefox.
- Added `modules/nixos/dns.nix` for NetworkManager/systemd-resolved
  integration, fallback DNS resolvers, opportunistic DNS-over-TLS, and DNSSEC
  allow-downgrade.
- Added `modules/nixos/firewall.nix` for the default-deny inbound firewall
  baseline with no custom open ports.
- Added `modules/nixos/hardware-intel.nix` for Intel CPU microcode updates on
  `war`.
- Added `modules/nixos/nix-maintenance.nix` for weekly garbage collection,
  14-day generation retention, and weekly store optimisation.
- Added `modules/nixos/networking.nix` for the shared NetworkManager baseline:
  wired and wireless managed by NetworkManager, Wi-Fi backed by iwd,
  auto-connect enabled, IPv6 allowed in iwd, and Wi-Fi power saving disabled for
  workstation reliability.
- Added `modules/nixos/packages.nix` for the minimal shared system package
  baseline. The larger old package list will be reviewed later in capability
  groups instead of copied wholesale.
- Added `modules/nixos/performance.nix` with the old config's
  developer-focused sysctl tuning, irqbalance enabled, and systemd-oomd for
  better behavior under memory pressure on systems without swap. Swap, zram, VM
  tuning, and broader CPU power policy remain deferred.
- Added `modules/nixos/ssh.nix` for SSH client agent startup. OpenSSH server,
  key management, GnuPG agent integration, and Home Manager SSH config remain
  deferred.
- Added `modules/nixos/storage.nix` for `/tmp` cleanup on boot, weekly TRIM,
  and monthly Btrfs scrub of `/`.
- Added `modules/nixos/users.nix` for the local `r` user, mutable password
  management, sudo policy, and access groups for networking, audio, graphics,
  seat/session handling, and administration.
- `hosts/war/configuration.nix` keeps host-specific identity, tmpfiles policy,
  and `system.stateVersion`.
- Shell, package ownership, additional users, and Home Manager remain deferred.

## Phase 2A: CPU And GPU Baseline

Status: In progress

- Prioritize CPU and GPU support earlier than desktop polish because missing
  hardware support caused gaps in the previous configuration.
- CPU baseline starts with vendor microcode. Add performance, scheduler, power,
  thermal, and virtualization tuning only when the target machine needs it.
- GPU baseline should cover `hardware.graphics`, Mesa, Vulkan, VA-API/video
  acceleration, and 32-bit graphics where justified.
- Do not guess vendor-specific GPU policy. Inspect the target hardware before
  adding Intel, AMD, NVIDIA, hybrid, passthrough, or VM graphics settings.

Current note:

- `war` imports `modules/nixos/hardware-intel.nix` because its generated
  hardware config loads `kvm-intel`.
- Added inactive `modules/nixos/graphics-nvidia.nix` for the real `war`
  desktop's NVIDIA GeForce RTX 4060 Ti: proprietary NVIDIA driver selection,
  hardware graphics, 32-bit graphics support, NVIDIA DRM modesetting, the open
  NVIDIA kernel module, and `nvidia-settings`.
- `graphics-nvidia.nix` is intentionally not imported into `war` yet because
  the current VM test path likely uses virtual graphics and may not have NVIDIA
  GPU passthrough.

## Phase 3: Home Manager And Dotfile Policy

Status: In progress

- Add Home Manager as a flake input and integrate it through the NixOS module
  system so `nixos-rebuild` activates system and user configuration together.
- Add a user profile for `r`.
- Define Home Manager base settings for XDG cleanliness.
- Add a file-management module that supports store-managed config by default
  and explicit opt-in live links from `dotfiles/` for high-churn configs.
- Document the live dotfile lifecycle: Home Manager owns the symlink, the repo
  owns the `dotfiles/` source, rebuilds are needed for link declaration changes,
  and stable configs should be promoted to store-managed Home Manager.
- Migrate stable configuration only after reviewing, adapting, and improving
  each old dotfile individually.

Current note:

- Added baseline Home Manager integration through the NixOS module system. The
  root flake includes the Home Manager input, `war` imports
  `modules/nixos/home-manager.nix`, and `users/r/home.nix` defines the minimal
  home profile for user `r`. Dotfiles, live links, program modules, packages,
  and shell changes remain deferred.
- Added `modules/home-manager/base.nix` and imported it from `users/r/home.nix`
  to enable Home Manager's XDG base directory support for cache, config, data,
  and state paths.
- Added the Home Manager file workflow scaffold: `repoPath` is passed to Home
  Manager, `modules/home-manager/files.nix` defines the future `dotfiles/`
  live-link helper, and `dotfiles/README.md` documents the workflow. No live
  links or real dotfiles have been added yet.
- Added the first real Home Manager configs: Starship is store-managed through
  `modules/home-manager/starship.nix`, and Lazygit is live-linked from
  `dotfiles/lazygit/config.yml`.

## Phase 4: Wayland And Mango Desktop

Status: In progress

- Add the reusable Wayland baseline: graphics, XWayland, portals, XDG desktop
  integration, toolkit environment variables, and support tools.
- Add greetd as the minimal login manager.
- Add Mango through the NixOS `mangowc` support from nixpkgs.
- Link or manage the Mango config only after reviewing and improving the old
  config and confirming required helper packages.
- Add clipboard, screenshot, bar, launcher, notification, wallpaper, media key,
  and monitor utilities as a coherent desktop slice.

Current note:

- Added inactive `modules/nixos/wayland.nix` for XWayland, seatd, XDG desktop
  integration, portals, Wayland toolkit environment variables, and helper
  packages. It is intentionally not imported into `war` yet so the current
  SDDM/Plasma VM fallback remains unchanged.

## Phase 5: User Applications And Ergonomics

Status: In progress

- Migrate zsh, Starship, WezTerm, lazygit, and Neovim incrementally.
- Add browser configuration after deciding the browser target and which
  settings belong in Nix versus browser-managed profile state.
- Add PDF, image, password, development-language, project-search, process
  management, and skim helper workflows as separate feature slices.
- Prefer small reviewed package additions over copying old package lists.
- Keep experimental configs live-editable until they stabilize.

Current note:

- Added zsh as user `r`'s login shell, enabled system zsh support, added the
  zsh autosuggestions, completions, and syntax-highlighting packages, and
  live-linked `dotfiles/zsh/.zshenv` and `dotfiles/zsh/.zshrc` through Home
  Manager. The files started from the old config and were kept live-editable,
  with only the minimal startup-path fixes needed for this NixOS layout.
- Wired the zsh completions package into `fpath` before `compinit`, moved
  syntax highlighting to the end of `.zshrc`, live-linked the fzf defaults file,
  and expanded zsh git aliases so they no longer depend on unmanaged global git
  alias definitions.

## Phase 6: Deferred Workstation Features

Status: Not started

- Add secrets with sops-nix only when a real secret consumer exists.
- Add Disko, LUKS, installer scripts, and local ISO or `nixos-anywhere`
  workflows only after the staged running system is stable.
- Add gaming, Docker, VR, custom audio routing, graphics vendor tuning, and
  hardware-specific udev rules only when the target machine requires them.
- Add package overlays, custom packages, or helper libraries only when there is
  real duplication or a concrete local package to expose.
- Keep `death`, `conquest`, and `wrath` as planned future hosts until their
  hardware and role-specific requirements are ready.

## Validation And Promotion

Status: Not started

- For each coherent slice, run available static checks and Nix evaluation.
- Build before temporary activation.
- Use `nixos-rebuild test` only after a successful build and explicit user
  approval.
- Use `nixos-rebuild switch`, reboot, bootloader changes, and promotion only
  after separate explicit approval.
- The staged project is promotion-ready only when it evaluates, builds,
  temporarily activates, persistently activates, survives reboot, rebuilds from
  its source, and no active path depends on old reference directories.

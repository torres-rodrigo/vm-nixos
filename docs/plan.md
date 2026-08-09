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
- The configuration has been promoted to the project root and validated through
  VM rebuild/reboot testing.

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
- The temporary Plasma/SDDM fallback has been retired from the active VM module
  graph. Firefox and printing remain available through focused standalone
  modules.
- Added `modules/nixos/dns.nix` for NetworkManager/systemd-resolved
  integration, fallback DNS resolvers, opportunistic DNS-over-TLS, and DNSSEC
  allow-downgrade.
- Added `modules/nixos/firewall.nix` for the default-deny inbound firewall
  baseline with no custom open ports.
- Added `modules/nixos/fonts.nix` to install Noto, Caskaydia Cove Nerd Font,
  project-owned fonts packaged from `assets/fonts/`, and fontconfig defaults.
  The active custom font assets are `Autism.ttf`, `Aspergers.ttf`, and
  `Excalifont-Regular.ttf`. Iosevka and the custom DOOM Nerd Font asset were
  removed from the active VM font configuration.
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
- Shell, Home Manager, and package ownership have started moving into focused
  modules. Additional users remain deferred until there is a concrete second
  account to model.

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
  `modules/nixos/home-manager.nix`, and `users/r/home.nix` defines the home
  profile for user `r`.
- Added `modules/home-manager/base.nix` and imported it from `users/r/home.nix`
  to enable Home Manager's XDG base directory support for cache, config, data,
  and state paths, user session variables, PATH additions, and declared
  tool/cache directories.
- Added the Home Manager file workflow: live-editable files are linked from
  `/etc/nixos/dotfiles` through `modules/home-manager/files.nix`, while stable
  configs stay store-managed in Home Manager modules.
- Added real Home Manager configs: Starship and Git are store-managed, while
  Lazygit, fzf, `.zshenv`, and `.zshrc` are live-linked from `dotfiles/`.
- Explicitly managed Home Manager files use `force = true` so migration from
  unmanaged VM config replaces target files instead of failing activation.

## Phase 4: Wayland And Mango Desktop

Status: In progress

- Add the reusable Wayland baseline: graphics, XWayland, portals, XDG desktop
  integration, toolkit environment variables, and support tools.
- Add greetd as the minimal login manager.
- Add Mango through the NixOS `programs.mango` support from nixpkgs.
- Link or manage the Mango config only after reviewing and improving the old
  config and confirming required helper packages.
- Add clipboard, screenshot, bar, launcher, notification, wallpaper, media key,
  and monitor utilities as a coherent desktop slice.

Current note:

- Added `modules/nixos/wayland.nix` for XWayland, seatd, XDG desktop
  integration, portals, Wayland toolkit environment variables, and helper
  packages.
- Started the safe Mango transition slice: `wayland.nix` is imported into
  `war`, `modules/nixos/mango.nix` enables Mango through current nixpkgs
  `programs.mango` and registers a UWSM-managed Mango session. A minimal
  VM-safe Mango config is live-linked from `dotfiles/mango/config.conf`.
- After SDDM-based testing exposed display-manager and graphics noise, the VM
  pivoted to the intended login stack: Plymouth for graphical boot/LUKS handoff
  and greetd autologin into Mango through UWSM. Added visible Mango startup
  helpers: `swaybg`, `mako`, `soteria`, `rofi`, `libnotify`, polkit, and an
  autostarted WezTerm. Plasma and SDDM are no longer active.
  If it fails, collect `journalctl -b -t war-mango-session --no-pager`,
  `journalctl -b -u greetd --no-pager`, `journalctl --user -b --no-pager`,
  and `/home/r/.local/state/war/mango-session.log`.

## Phase 4A: Greetd And Plymouth Boot Flow

Status: In progress

- Added `modules/nixos/greetd.nix` to start Mango through UWSM as user `r`
  after boot, with `tuigreet` as the manual fallback session.
- Added `modules/nixos/plymouth.nix` and repo-local Plymouth assets under
  `assets/plymouth/` for the graphical boot and LUKS unlock path.
- Removed the active `desktop-plasma.nix` module and moved Firefox and printing
  into standalone modules so the Mango config keeps its browser binding without
  retaining Plasma/SDDM.
- After the first encrypted VM test hung behind Plymouth, the installer was
  changed to write the encrypted hardware configuration explicitly instead of
  relying on `nixos-generate-config` to infer LUKS and Btrfs subvolumes.
  greetd now uses an automatic `initial_session` for user `r` to start Mango
  through UWSM, with `tuigreet` retained as the manual fallback session.
- After autologin and every manual Mango session bounced back to greetd, greetd
  was changed to launch Mango through a `war-mango-session` logging wrapper.
  The current GNOME Boxes VM has reported QXL graphics in the guest journal;
  switch the host-side video device to Virtio with 3D/OpenGL before treating a
  compositor DRM failure as a NixOS configuration issue.
- After the wrapper showed `uwsm start` returning status `0` while greetd
  returned to `tuigreet`, the wrapper was changed to use UWSM's bound-session
  flow: generate runtime units, bind the session to the wrapper PID, and wait
  on `wayland-wm@mango.service`.
- After the plain Mango session also bounced and `/dev/dri` showed only a card
  node under GNOME Boxes/QXL, the wrapper was changed to apply VM-safe wlroots
  fallbacks: `WLR_RENDERER=pixman`, `WLR_NO_HARDWARE_CURSORS=1`, and
  `WLR_DRM_NO_ATOMIC=1`.

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

## Phase 6: Encrypted VM Installer

Status: In progress

- Added the first encrypted local-ISO install workflow for `war`.
- Added `install/disko-config.nix` for a UEFI, LUKS2, Btrfs subvolume layout.
- Added a flake app, `install-encrypted-vm`, that lists available whole disks,
  prompts for one shared LUKS/root/user `r` password, runs Disko, generates the
  target hardware configuration, copies the complete Git checkout to
  `/mnt/etc/nixos`, and installs `.#war` with temporary password hashes.
- Added `docs/encrypted-vm-install.md` with the clone, dry-run, install,
  reboot, and post-install Git workflow. The installed system keeps
  `/etc/nixos/.git`, so it can continue pulling and rebuilding from
  `/etc/nixos`.
- This installer is destructive and should only be run from a NixOS ISO against
  a disposable VM disk or intended target disk.
- Wired the zsh completions package into `fpath` before `compinit`, moved
  syntax highlighting to the end of `.zshrc`, live-linked the fzf defaults file,
  and expanded zsh git aliases so they no longer depend on unmanaged global git
  alias definitions.
- Reduced `.zshenv` to early zsh bootstrap only. Home Manager now owns user
  session variables, PATH additions, and creation of the declared tool/cache
  directories and zsh history file.
- Added store-managed Git configuration through Home Manager, including the
  requested Git defaults, delta settings, `gh:` URL shortcut, and a managed
  global ignore file.
- Moved the managed user `.zshenv` link into `~/.config/zsh`; NixOS zsh
  initialization now sets `ZDOTDIR`, and `.zshenv` directly exports the
  Starship and fzf config paths needed during early shell startup.

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

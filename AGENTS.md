# Staged NixOS Project Guide

## Mission

Build the replacement NixOS configuration here. The target is a maintainable,
flake-based Mango/Wayland workstation for user `r`, initially validated on the
current x86_64 NixOS VM.

The old `/home/r/nixos/nixos` configuration is a base/example to learn from and
improve upon, not something to copy wholesale. Every reused module, asset, or
dotfile must be reviewed against current NixOS options, adapted to this
architecture, and improved where the old design was weak.

## Fixed Decisions

- Preserve `system.stateVersion = "26.05"` unless the user explicitly chooses a
  different compatibility baseline. Never bump it merely because nixpkgs moves.
- Use flakes as the single entry point for evaluation, rebuilds, and integrated
  Home Manager activation.
- Start with one host for this VM while keeping host-specific hardware and
  identity separate from reusable modules.
- Build toward Mango with Wayland, greetd, PipeWire, and XDG integration. Do not
  pull in a complete desktop environment unless a reviewed requirement needs it.
- Integrate Home Manager through the NixOS module system; do not require a
  separate `home-manager switch` workflow.
- Defer Disko, disk encryption layout, and local-ISO installation tooling until
  the running workstation configuration is complete and stable.

## Architecture and Conventions

- Keep `flake.nix` small. Put host assembly and other output logic in focused
  files when it becomes large enough to justify them.
- Separate reusable NixOS modules, Home Manager modules, host definitions,
  user profiles, assets, and documentation.
- Use explicit imports. Avoid implicit `default.nix` aggregators and directory
  scanning that hides the active module graph.
- Keep hardware-generated settings in the host hardware file and host identity
  in the host definition. Do not embed the staging path or legacy repository
  path in reusable modules.
- Prefer NixOS modules for system services and policy, and Home Manager for
  genuinely user-scoped configuration. Avoid duplicating ownership of the same
  setting across both layers.
- Home Manager, if enabled, must be integrated through the NixOS module system
  so `nixos-rebuild` activates system and user configuration together; do not
  require a separate `home-manager switch` workflow.
- Prefer store-managed configuration. Reserve `dotfiles/` for explicitly
  selected live-editable config sources linked with Home Manager
  `mkOutOfStoreSymlink`; never put secrets, generated state, caches, or
  unpredictably app-rewritten files there.
- Project-owned assets must be copied under `assets/` and consumed through
  explicit NixOS or Home Manager modules. Font originals can be developed
  outside the repository, but active Nix font configuration must reference only
  copied files under `assets/fonts/`.
- Keep packages close to the capability that needs them; maintain a small shared
  system package baseline rather than an unexplained package dump.
- Add abstractions only after a repeated need is visible. Clear, explicit Nix is
  preferred over premature generic host frameworks.
- Document intentional security, compatibility, or performance tradeoffs next
  to the relevant option.

## Delivery Plan

Work in small, buildable phases:

1. Create a minimal locked flake and a host that reproduces the current VM's
   bootable hardware, networking, locale, user, and Nix baseline.
2. Extract reviewed reusable system modules for boot, maintenance, networking,
   audio, graphics, fonts, security, and packages.
3. Integrate Home Manager and establish the XDG/dotfile policy.
4. Add and validate the Mango, greetd, Wayland, portal, and session baseline.
5. Add applications and user configuration incrementally, with a build after
   each coherent feature.
6. Add secrets scaffolding only when a real secret consumer exists.
7. Complete activation, reboot, rollback, and promotion validation.

Maintain a separate roadmap or status document once implementation begins.
Keep this file focused on durable purpose, constraints, and workflow; update it
when those durable decisions change.

## Validation and Activation

Use the checks supplied by the project. Until wrappers exist, the expected
sequence from this directory is:

```console
nix fmt -- --check .
statix check .
deadnix .
nix flake show --no-write-lock-file
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
```

If a tool is not yet declared or a check is not applicable to the current
bootstrap phase, report that limitation instead of silently skipping it. Do not
update `flake.lock` during a validation-only command.

After a successful build, temporary activation uses:

```console
sudo nixos-rebuild test --flake .#war
```

Exercise the affected behavior after activation. Persistent activation uses
`nixos-rebuild switch` only after reporting successful checks and receiving
explicit user approval. Reboot only with the same explicit approval and a known
rollback generation.

## Definition of Ready for Promotion

The project is ready for the full workstation milestone only when its flake
evaluates, builds, temporarily activates, persistently activates, survives
reboot, and can rebuild from its source; Mango provides a usable session;
networking, audio, graphics, portals, user access, and Home Manager integration
work; secrets are not committed; and no runtime or evaluation path depends on
the old `/home/r/nixos/nixos` reference project.

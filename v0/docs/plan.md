# v0 NixOS Plan

## Summary

v0 is a from-scratch NixOS workstation configuration. The target is a
performance-focused, secure, modular, Wayland-first system with a small service
footprint and explicit ownership boundaries between hosts, reusable modules,
users, dotfiles, assets, and installation tooling.

This file tracks requirements, roadmap status, and open decisions. Durable
Codex behavior belongs in `v0/AGENTS.md`.

## Requirements

### Performance And Resource Usage

- Minimize idle RAM usage and the number of running services.
- Enable only required system services and background processes.
- Avoid telemetry, indexing, automatic update daemons, and similar background
  jobs unless explicitly accepted.
- Prefer lightweight tools where they meet the requirement.
- Avoid duplicated functionality between services.
- Use service hardening and resource limits where practical.
- Explain the cost of any nonessential service that is enabled.

### Security

- Use secure defaults for networking, kernel behavior, service exposure, and
  privilege escalation.
- Enable a firewall by default.
- Add secrets management only when a real secret consumer exists.
- Keep secrets, generated state, caches, and machine-local mutable data out of
  the repository.
- Prefer `doas` over `sudo`, while keeping a `sudo` compatibility alias if it
  does not weaken the privilege model.

### Graphics And Desktop

- Build a Wayland-first desktop.
- Prefer Wayland-native applications and set Wayland environment defaults where
  appropriate.
- Keep XWayland available for compatibility.
- Support Nvidia graphics.
- Support hybrid graphics so the dedicated GPU is used only when needed.
- Avoid pulling in a complete desktop environment unless a reviewed requirement
  needs it.

### Power

- Sleep is supported.
- Hibernation is out of scope.
- Do not configure swap or zram.

### Installation And Storage

- Use Disko for the install storage layout.
- Maintain an install script that can run from a NixOS ISO.
- Prompt for the supported host target and use that selection as the installed
  system hostname.
- Prompt for the primary username during install.
- Warn clearly before destructive disk operations.
- Keep the install path flexible while v0 is still staged under `/etc/nixos/v0`.

### User Environment

- Use flakes as the entry point.
- Prefer NixOS-only user environment management for the single-user
  workstation.
- Configure session variables through NixOS system-level options.
- Configure shell behavior through NixOS `programs.<shell>` options and managed
  dotfiles.
- Support live-editable configuration only for explicitly selected dotfiles.
- Symlink selected paths from `v0/dotfiles/` into the user's `.config` through a
  dedicated NixOS-owned mechanism.
- Defer Home Manager unless a concrete later requirement makes NixOS-only
  management awkward or insufficient.
- Replace common shell tools with modern alternatives where useful:
  `ls` to `eza`, `find` to `fd`, and `cat` to `bat`.
- Remove unused default software such as `nano` when practical.
- Add fingerprint support if it can be done without an unacceptable service or
  security tradeoff.

## Repository Layout

Target v0 layout:

```text
v0/
|- assets/
|- docs/
|- disko/
|- secrets/
|- hosts/
|- scripts/
|- users/
|- dotfiles/
|- modules/
|- README.md
|- flake.nix
|- flake.lock
|- install.sh
```

Use explicit imports. Add abstractions only after repeated need is visible.

## Roadmap

| Phase | Status | Goal |
| --- | --- | --- |
| 1. Installer and Disko baseline | In progress | Validate the destructive install flow, encrypted Disko layout, prompts, and warnings. |
| 2. Minimal flake and host boot baseline | Not started | Add a locked flake and at least one bootable host with hardware, locale, user, networking, and Nix baseline. |
| 3. Users, privilege, security, networking | Not started | Add user policy, `doas`, firewall, network security, and kernel/security defaults. |
| 4. Graphics and Wayland | Not started | Add Wayland session baseline, XWayland compatibility, Nvidia, and hybrid graphics policy. |
| 5. User environment and dotfiles | Not started | Configure session variables, shell behavior, user environment, and live-editable dotfile links through NixOS. |
| 6. Applications and CLI tools | Not started | Add reviewed applications and shell tool replacements without creating package dumps. |
| 7. Secrets and final validation | Not started | Add secrets scaffolding for real consumers and complete manual build/install validation. |

## Open Decisions

- Which host should be the first v0 boot target after the installer work:
  `war`, `conquest`, or a new minimal host?
- Which Wayland compositor/session should v0 target first?
- Which secrets mechanism should be used once a real secret consumer exists?
- What exact fingerprint hardware and PAM integration are required?
- Which Nvidia offload command/wrapper should be exposed to users?
- Should Home Manager be introduced later, and if so, which concrete
  user-scoped requirement justifies it?

## Validation

Codex may run non-mutating checks only. The user runs NixOS builds manually.

Expected checks as the v0 project grows:

```console
nix fmt -- --check .
statix check .
deadnix .
nix flake show --no-write-lock-file
nix flake check --no-build
```

Report missing tools or inapplicable checks explicitly. Do not update
`flake.lock` during validation-only work.

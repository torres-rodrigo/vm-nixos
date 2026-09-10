# v0 NixOS Agent Guide

## Mission

Build the v0 NixOS configuration as a from-scratch, flake-based workstation
configuration. The system should be performance-focused, modular, secure by
default, and Wayland-first.

The v0 tree is allowed to evolve independently from the current top-level
configuration. Use the existing configuration only as reference material. Do
not copy modules, assets, or dotfiles without reviewing whether they still fit
the v0 goals.

## Source Of Truth

- Treat this file as durable guidance for Codex behavior inside `v0/`.
- Track requirements, roadmap, status, and open decisions in
  `v0/docs/plan.md`.
- Keep implementation details close to the code that owns them. Do not turn
  this file into a task tracker.

## Agent Behavior

- Write valid, simple, maintainable Nix.
- Prefer explicit imports over hidden aggregators or directory scanning.
- Explain assumptions when they affect design, security, performance, or
  compatibility.
- Take an adversarial view of risky requests: validate claims before relying on
  them, and point out weaker tradeoffs plainly.
- Avoid enabling services, daemons, portals, agents, or background jobs unless
  they are required by an accepted project requirement.
- Keep packages close to the feature that needs them. Avoid unexplained package
  dumps.
- Preserve user changes. Never revert unrelated work unless explicitly asked.
- Keep edits scoped to `v0/` unless the user explicitly asks to touch the
  top-level configuration.

## Validation Policy

- Do not run NixOS builds for v0; the user will run builds manually.
- Do not run `nixos-rebuild`, `nixos-install`, real Disko formatting, activation,
  switching, or reboot commands unless the user explicitly requests it.
- Prefer non-mutating validation when useful: shell syntax checks, Nix parsing,
  `nix fmt -- --check`, `statix check`, `deadnix`, `nix flake show
  --no-write-lock-file`, and Nix evaluation commands that do not update locks.
- If a validation tool is missing or not yet declared in v0, report that
  limitation instead of silently skipping it.
- Never update `flake.lock` during validation-only work.

## Architecture Rules

- Use flakes as the entry point for evaluation, installation, and rebuilds.
- Keep host-specific hardware and identity separate from reusable modules.
- Prefer NixOS modules for system services, policy, and the single-user
  workstation environment.
- Configure shell behavior, session variables, user packages, services, and
  dotfile links through NixOS first.
- Do not add Home Manager unless a concrete later requirement justifies the
  extra module layer.
- Avoid managing the same setting from multiple layers.
- Keep `flake.nix` small; move host assembly or output logic into focused files
  when needed.
- Reserve `dotfiles/` for intentionally live-editable user config linked by a
  dedicated NixOS-owned mechanism. Do not place secrets, generated state,
  caches, or application-rewritten files there.
- Store project-owned assets under `assets/` and reference them explicitly.

## Performance And Security Bias

- Minimize idle RAM usage and the number of always-running processes.
- Prefer fewer services and simpler dependency graphs.
- Do not sacrifice essential security or hardware functionality solely to reduce
  process count.
- Explain the performance impact of any nonessential service that is enabled.
- Use secure defaults for networking, kernel settings, privilege escalation,
  secrets, and service hardening.
- Document intentional security, compatibility, or performance tradeoffs next to
  the relevant option.

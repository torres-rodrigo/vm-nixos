# NixOS Workspace Guide

## Purpose

This workspace is used to develop a complete NixOS workstation configuration
without prematurely replacing the configuration that currently boots this VM.

The intended end state is a flake-based, modular Mango/Wayland workstation.
Development happens under `nixos/` until that configuration has been built,
activated, reboot-tested, and judged ready to replace the files at this level.

## Workspace Layout

- `configuration.nix` and `hardware-configuration.nix` are the current live
  fallback configuration. Preserve them until the staged configuration is
  formally promoted.
- `nixos/` is the new configuration project and the only place for new NixOS
  implementation work. Its nested `AGENTS.md` supplies project-specific rules.
- `.nixos/` is the previous, independently versioned attempt. Treat it as
  read-only reference material. Its incomplete modules, documents, assets, and
  dotfiles may inform new work but are not authoritative.

Instructions in a deeper `AGENTS.md` add to or override these instructions for
files in that directory.

## Source-of-Truth Rules

- Do not edit the live fallback files while implementing staged features unless
  the user explicitly requests a live-system change.
- Do not edit `.nixos/`, its Git metadata, or its history. Do not run its
  installer or any destructive Disko workflow.
- Never copy `.nixos/` wholesale. Review reusable ideas and files individually,
  adapt them to the new architecture, and validate them in `nixos/`.
- Do not assume the old project's hostname, repository path, hardware, package
  options, or completion notes are correct. Its host imports a missing hardware
  configuration and its roadmap records unfinished work.
- Current machine facts come from the live configuration and the running VM.
  Keep generated hardware configuration isolated in the staged host and do not
  hand-edit it without a concrete hardware reason.

## Safety and Change Policy

- Keep changes small, explicit, reviewable, and reversible.
- Never store plaintext passwords, tokens, private keys, LUKS passphrases, or
  other secrets in Git. Use placeholders or an approved secrets mechanism.
- Treat partitioning, formatting, encryption changes, and installer execution
  as destructive. They require a separate explicit user request and exact
  target confirmation.
- A successful evaluation is not permission to activate. Build before testing;
  use temporary activation before a persistent switch.
- Before `nixos-rebuild switch`, rebooting, or changing the bootloader, report
  what was validated and obtain explicit user approval.
- Preserve a bootable prior generation and documented rollback route when
  testing the staged system.
- Do not run formatters in rewrite mode unless formatting changes are intended.

## Git Policy

`/etc/nixos` is the repository root for the new work. The nested `.nixos/`
repository stays independent and is ignored by the parent repository. Do not
remove its `.git` directory, convert it to a submodule, or commit it through the
parent repository.

Do not create commits, rewrite history, or configure remotes unless the user
asks. Keep generated Nix result links and local secret material untracked.

## Staging and Promotion

The staged flake may be evaluated, built, and temporarily activated directly
from `/etc/nixos/nixos`; moving it first is neither necessary nor desired.

Promotion is allowed only when all of the following are true:

1. Static checks and flake evaluation pass.
2. The intended host configuration builds successfully.
3. `nixos-rebuild test` succeeds on this VM.
4. A persistent activation and reboot have been explicitly approved and tested.
5. The system can rebuild again from the staged source after reboot.
6. No active module depends accidentally on `.nixos/` or on a path that will
   disappear during promotion.
7. The prior generation remains available for rollback.

At promotion time, move the staged project contents into `/etc/nixos`, reconcile
this file with `nixos/AGENTS.md` into one accurate root guide, rebuild from the
new root path, and only then remove obsolete fallback files. Removal is a
separate, explicit operation; do not infer permission from readiness alone.

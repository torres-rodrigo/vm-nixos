# Goal
Build a NixOS configuration. The configuration should be performanced focused and modular.
The configuration should focus on minimizing RAM usage and the number of processces the system uses at all times.
- Low RAM usage
- Minimanl number of running processes and enabled services
- Wayland-first desktop configuration
- Secure defaults
- Modular & maintainable system

# Agent behaviour
- Make sure to write valid nix code & configurations, but never run test builds the user will do them manually
- Explain assumptions
- Explain security & performance tradeoffs
- Take an adversarial view to requests, validate them before taken them as true.
- Avoid enabling services that were not requested
- Prefer simple, maintainable Nix over unnecessarily clever abstractions.

# Performance and resource usage
- Minimize idle RAM consumption.
- Enable only required services and system processes.
- Avoid unnecessary background daemons, telemetry, indexing, and automatic update services.
- Prefer lightweight alternatives where practical.
- Avoid duplicate functionality between services.
- Use systemd service hardening and resource limits where appropriate.
- Do not sacrifice essential security or hardware functionality solely to reduce process count.
- Explain the performance impact of every nonessential service that is enabled.

# Security


# Graphics
- Wayland system that should prioritizes wayland first programs and sets wayland mode for programs 
- XWayland for compatibility
- Nvidia drivers
- Hybrid ghraphics set up, that only uses dedicated gpu when performance needs it

# Power management
- Sleep mode only, no hybernantion
- No swap or zram


Some system requierments
Network security
kernel security
secrets management
fingerprint
wayland first
live updatable configurations
disko
install script
no swap, only sleep mode no hybernation
nvdia drivers
firewall
replace sudo with doas but keep sudo alias
remove and replace tools ls -> eza, find -> fd, cat -> bat, etc keep basic aliases
unsed nixos software should be removed example nano
flake.nix & flake.lock

.
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

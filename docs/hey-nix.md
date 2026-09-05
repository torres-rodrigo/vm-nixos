# Heytcass Nix Security Notes

## Goal

This document audits the NixOS configuration in
`/home/r/sys_configs/heytcass-nix-config` for security-relevant firewall,
kernel, and networking settings. It compares those settings with the current
configuration in `/etc/nixos` and records improvements worth considering here.

The reference configuration is useful as a reviewed source of ideas, not as a
module to copy wholesale. The active reference host graph imports
`modules/common-imports.nix`, which includes the relevant `boot.nix`,
`networking.nix`, `security.nix`, `performance.nix`, and `systemd.nix` modules
for both `gti` and `transporter`.

## Source Map

Reference sources inspected:

| Area | Reference source | Notes |
| --- | --- | --- |
| Firewall and DNS | `/home/r/sys_configs/heytcass-nix-config/modules/networking.nix` | NetworkManager, resolved, firewall, Tailscale, time sync. |
| Kernel and system security | `/home/r/sys_configs/heytcass-nix-config/modules/security.nix` | Network sysctls, kernel information restrictions, sudo, AppArmor, auditd, fail2ban. |
| Boot and kernel package | `/home/r/sys_configs/heytcass-nix-config/modules/boot.nix` | systemd-boot policy, latest kernel, initrd, kernel parameters. |
| Secure boot and TPM | `/home/r/sys_configs/heytcass-nix-config/modules/secure-boot.nix` | Disabled lanzaboote scaffold, TPM2 support, secure boot tooling. |
| Hardware baseline | `/home/r/sys_configs/heytcass-nix-config/modules/hardware.nix` | Intel microcode, Bluetooth, hardware services, zram. |

Current sources inspected:

| Area | Current source | Notes |
| --- | --- | --- |
| Firewall | `modules/nixos/firewall.nix` | Default-deny inbound firewall with no opened ports. |
| Networking | `modules/nixos/networking.nix` | NetworkManager with iwd backend and Wi-Fi power-save disable rule. |
| DNS | `modules/nixos/dns.nix` | systemd-resolved, fallback resolvers, opportunistic DNS-over-TLS. |
| Boot and kernel | `modules/nixos/boot.nix` | systemd-boot, latest kernel, disabled boot editor. |
| Sysctls | `modules/nixos/performance.nix` | Developer/performance sysctls, not a full hardening set. |
| Hardware security-adjacent | `modules/nixos/hardware-intel.nix`, `modules/nixos/thunderbolt.nix` | Intel microcode and Bolt for Thunderbolt authorization. |

## Firewall

### Reference Configuration

The reference enables the NixOS firewall:

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ ];
  allowedUDPPorts = [ ];
  allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
};
```

`networking.firewall.enable = true` turns on the default NixOS packet filter.
For a workstation, this is the right baseline: inbound traffic is denied unless
a rule explicitly opens it.

`allowedTCPPorts = [ ]` and `allowedUDPPorts = [ ]` mean no single inbound TCP
or UDP ports are opened.

The TCP and UDP range `1714-1764` is for KDE Connect device discovery and
communication on the local network. This is a convenience feature, but it is
still an exposure: any network the machine joins can attempt connections across
that range unless additional interface or source restrictions are added.

### Current Configuration

The current configuration is stricter:

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ ];
  allowedUDPPorts = [ ];
};
```

There are no open single ports and no open port ranges. This matches the
project requirement for a default-deny inbound workstation firewall.

### Improvement Notes

- Keep the current firewall baseline. It is simpler and more restrictive than
  the reference.
- Do not add the KDE Connect range globally unless KDE Connect becomes a real
  requirement.
- If KDE Connect is added later, put the port range in a focused module near
  the KDE Connect package/service choice, with a comment explaining why the LAN
  exposure is acceptable.
- For future services such as SSH, file sharing, or development servers, open
  only the required ports and document whether the service should be reachable
  on all interfaces, only trusted LANs, or only a VPN interface.

## Networking

### Reference Configuration

The reference enables NetworkManager:

```nix
networking.networkmanager.enable = true;
networking.networkmanager.wifi.powersave = false;
```

NetworkManager is the expected general-purpose workstation network stack. The
Wi-Fi power-save setting prioritizes connection latency and stability over
battery life. That can help laptops with unstable Wi-Fi, but it spends more
power.

The reference enables `systemd-resolved`:

```nix
services.resolved = {
  enable = true;
  dnssec = "false";
  dnsovertls = "opportunistic";
};
```

`services.resolved.enable = true` uses systemd-resolved for local name
resolution. `dnsovertls = "opportunistic"` attempts encrypted DNS when the
selected resolver supports it, but allows fallback to plaintext DNS. That is a
compatibility-first privacy improvement rather than a strict privacy boundary.

`dnssec = "false"` disables DNSSEC validation. This avoids broken-network
compatibility problems, but it gives up resolver-side validation of signed DNS
zones.

The reference disables classic NTP and enables systemd time sync:

```nix
services.ntp.enable = false;
services.timesyncd.enable = true;
```

This avoids running two time synchronization implementations and uses the
lightweight systemd client. Accurate time matters for TLS, VPNs, logs, and
Kerberos-like protocols.

The reference enables Tailscale:

```nix
services.tailscale.enable = true;
```

Tailscale adds a WireGuard-based mesh VPN. It is useful for private remote
access, but it is also another always-on network service and trust boundary. It
should be enabled only when this workstation has a defined tailnet role.

### Current Configuration

The current config also uses NetworkManager, but with the iwd Wi-Fi backend:

```nix
networking.networkmanager = {
  enable = true;
  wifi.backend = "iwd";
};
```

It also explicitly enables iwd settings:

```nix
networking.wireless.iwd = {
  enable = true;
  settings = {
    Network.EnableIPv6 = true;
    Settings.AutoConnect = true;
  };
};
```

The current config disables Wi-Fi power save with a udev rule:

```nix
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
```

This has the same security-neutral performance intent as the reference
`wifi.powersave = false`, but it implements the policy at the wireless device
level. The current approach is probably related to the iwd backend choice and
should be validated on `conquest`.

The current DNS configuration is stronger than the reference on DNSSEC:

```nix
networking.networkmanager.dns = "systemd-resolved";

services.resolved = {
  enable = true;
  settings.Resolve = {
    DNSSEC = "allow-downgrade";
    DNSOverTLS = "opportunistic";
    FallbackDNS = [
      "9.9.9.9"
      "149.112.112.112"
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
};
```

NetworkManager is explicitly wired to systemd-resolved. DNSSEC
`allow-downgrade` attempts validation when possible while still tolerating
networks that cannot support it. DNS-over-TLS remains opportunistic, as in the
reference. The fallback resolvers are Quad9 and Cloudflare.

The current configuration does not enable Tailscale.

### Improvement Notes

- Keep NetworkManager as the base network manager.
- Keep the current systemd-resolved integration; it is more explicit than the
  reference because NetworkManager is told to use resolved.
- Keep DNSSEC `allow-downgrade` unless it causes real captive-portal or network
  compatibility problems. It is a better default than disabling DNSSEC.
- Keep opportunistic DNS-over-TLS for now. Strict DNS-over-TLS would be a
  stronger privacy policy, but it can break networks that intercept or restrict
  DNS.
- Confirm the iwd backend on `conquest` after activation. If Wi-Fi roaming,
  captive portals, or enterprise networks are unreliable, compare it against
  the default NetworkManager Wi-Fi backend before adding more network UI.
- Do not enable Tailscale by default. Add it only when the machine has a real
  remote-access or tailnet use case, ideally with firewall policy documented
  beside the service.
- Consider adding a small networking security module for kernel network
  sysctls, described below, because the reference has useful low-cost settings
  that are missing here.

## Kernel And Boot Security

### Reference Network Sysctls

The reference sets these network security sysctls:

```nix
boot.kernel.sysctl = {
  "net.ipv4.conf.default.rp_filter" = 1;
  "net.ipv4.conf.all.rp_filter" = 1;
  "net.ipv4.conf.default.log_martians" = 1;
  "net.ipv4.conf.all.log_martians" = 1;
  "net.ipv4.conf.all.accept_redirects" = 0;
  "net.ipv4.conf.default.accept_redirects" = 0;
  "net.ipv6.conf.all.accept_redirects" = 0;
  "net.ipv6.conf.default.accept_redirects" = 0;
  "net.ipv4.conf.all.secure_redirects" = 0;
  "net.ipv4.conf.default.secure_redirects" = 0;
  "net.ipv4.conf.all.accept_source_route" = 0;
  "net.ipv4.conf.default.accept_source_route" = 0;
  "net.ipv6.conf.all.accept_source_route" = 0;
  "net.ipv6.conf.default.accept_source_route" = 0;
};
```

`rp_filter = 1` enables strict reverse-path filtering for IPv4. The kernel
drops packets whose source address would not be routed back through the same
interface. This helps against simple spoofing. It can interfere with advanced
multi-homing, policy routing, asymmetric routing, containers, or VPN setups, so
it should be validated with Tailscale or other VPNs before adopting globally.

`log_martians = 1` logs packets with impossible or suspicious source routes.
This is useful for visibility when debugging hostile or broken networks. It can
increase log noise on messy LANs.

`accept_redirects = 0` rejects ICMP redirects for IPv4 and IPv6. Redirects let
routers tell a host to use a different next hop. Workstations rarely need to
trust these messages, and accepting them can help local network attackers
redirect traffic.

`secure_redirects = 0` disables even the narrower IPv4 redirect behavior that
trusts redirects from known gateways. Since redirects are not needed for this
workstation baseline, disabling them is cleaner.

`accept_source_route = 0` rejects source-routed packets for IPv4 and IPv6.
Source routing lets the sender influence the network path. It is obsolete for
normal workstation use and should stay disabled.

### Reference Kernel Information Sysctls

The reference also sets these kernel hardening sysctls:

```nix
boot.kernel.sysctl = {
  "kernel.dmesg_restrict" = 1;
  "kernel.kptr_restrict" = 2;
  "kernel.yama.ptrace_scope" = 1;
};
```

`kernel.dmesg_restrict = 1` prevents unprivileged users from reading kernel
logs through `dmesg`. Kernel logs can expose addresses, hardware details, and
driver state useful to local attackers.

`kernel.kptr_restrict = 2` hides kernel pointer addresses from userspace, even
for privileged readers in many procfs-style outputs. This reduces information
available for kernel exploit development.

`kernel.yama.ptrace_scope = 1` restricts process tracing so a process generally
cannot attach to arbitrary same-user processes unless there is a parent-child
debugging relationship or explicit permission. This limits credential and
memory scraping between desktop applications. It may affect debuggers,
profilers, crash handlers, and editor tooling that attach to already-running
processes.

### Reference Boot And Kernel Choices

The reference uses the latest kernel package:

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

This usually brings newer hardware support and security fixes sooner, at the
cost of a higher chance of driver regressions than the default stable kernel.

The reference disables the systemd-boot editor:

```nix
boot.loader.systemd-boot.editor = false;
```

This prevents editing boot entries from the bootloader UI. It is a sensible
baseline when physical attackers are out of scope for full disk compromise but
boot parameter tampering should not be made easy.

The reference limits retained boot entries:

```nix
boot.loader.systemd-boot.configurationLimit = 3;
```

This reduces boot menu clutter and old-generation exposure, but it also leaves
fewer rollback points.

The reference enables kernel image protection:

```nix
security.protectKernelImage = true;
```

This asks NixOS to apply kernel image protection where supported, reducing
some ways the running kernel can be modified or inspected.

The reference has a secure boot scaffold through lanzaboote, but it is disabled:

```nix
boot.lanzaboote.enable = false;
boot.lanzaboote.pkiBundle = "/etc/secureboot";
```

Because it is disabled, this is not active secure boot hardening. The module
does enable TPM2 support and installs secure boot and TPM tools, but those are
management capabilities rather than proof that the boot chain is currently
verified.

### Reference Service-Level Security

The reference enables sudo restrictions:

```nix
security.sudo = {
  enable = true;
  execWheelOnly = true;
  extraConfig = "Defaults timestamp_timeout=30";
};
```

`execWheelOnly = true` restricts sudo execution to wheel members. The timestamp
timeout keeps sudo authentication cached for 30 minutes. That is convenient but
less strict than a shorter timeout.

The reference enables AppArmor:

```nix
security.apparmor = {
  enable = true;
  killUnconfinedConfinables = true;
};
```

AppArmor is a mandatory access control system. It can limit damage from
confined applications, but only when useful profiles exist. Killing unconfined
confinable processes is a strict setting and can surprise users if profiles or
package integration are incomplete.

The reference enables auditd but disables the NixOS audit rules service:

```nix
security.auditd.enable = true;
security.audit.enable = false;
```

This starts the audit daemon without enabling a defined audit rule set. It may
be useful as future scaffolding, but by itself it is not a complete audit
policy.

The reference enables fail2ban:

```nix
services.fail2ban = {
  enable = true;
  maxretry = 3;
  bantime = "1h";
  ignoreIP = [
    "127.0.0.0/8"
    "10.0.0.0/8"
    "192.168.0.0/16"
    "172.16.0.0/12"
  ];
};
```

Fail2ban watches service logs and bans sources after repeated failures. It is
most useful when SSH or another login service is reachable from a network. On a
workstation with no inbound services, it adds little value.

The reference also enables YubiKey/FIDO support through `pcscd`,
`yubikey-agent`, udev packages, and `security.pam.u2f`. Those are valuable for
hardware-backed authentication, but they are outside the firewall, kernel, and
networking focus of this audit.

### Current Configuration

The current boot config already matches several good reference choices:

```nix
boot.loader.systemd-boot = {
  enable = true;
  configurationLimit = 5;
  editor = false;
};

boot.kernelPackages = pkgs.linuxPackages_latest;
```

The current configuration keeps two more rollback generations than the
reference. That is a good tradeoff for this staged workstation while the system
is still changing often.

The current sysctls are mostly performance and developer ergonomics:

```nix
boot.kernel.sysctl = {
  "fs.inotify.max_user_watches" = 524288;
  "fs.inotify.max_user_instances" = 512;
  "kernel.perf_event_paranoid" = 1;
  "net.core.rmem_max" = 134217728;
  "net.core.wmem_max" = 134217728;
  "net.ipv4.tcp_fastopen" = 3;
};
```

`kernel.perf_event_paranoid = 1` permits some performance profiling while
restricting more sensitive access. This is less strict than a hardening-first
desktop might choose, but it fits a development workstation.

`net.ipv4.tcp_fastopen = 3` enables TCP Fast Open for both client and server
behavior. It can reduce latency but changes TCP handshake behavior. On a
machine with no listening services, the server-side part has limited practical
effect.

The current config does not set the reference network hardening sysctls,
`dmesg_restrict`, `kptr_restrict`, `yama.ptrace_scope`, or
`security.protectKernelImage`.

The current config also does not enable AppArmor, auditd, fail2ban, or
Tailscale. SSH is limited to starting a user SSH agent:

```nix
programs.ssh.startAgent = true;
```

That does not expose an inbound SSH service.

Current Intel microcode is enabled:

```nix
hardware.cpu.intel.updateMicrocode = true;
```

This matches the reference and should stay enabled. Microcode updates are an
important part of CPU vulnerability mitigation.

Current Thunderbolt support enables Bolt:

```nix
services.hardware.bolt.enable = true;
```

This is security-relevant for `conquest`: Thunderbolt and USB4 devices can have
direct-memory-access implications depending on firmware and IOMMU policy. Bolt
keeps authorization explicit without pulling in a full desktop control stack.

## Improvement Candidates

### Good Candidates To Adopt Soon

- Add a focused `modules/nixos/security.nix` or
  `modules/nixos/kernel-hardening.nix` for low-risk kernel and network sysctls.
- Start with redirect rejection, source-route rejection, `dmesg_restrict = 1`,
  `kptr_restrict = 2`, and `security.protectKernelImage = true`.
- Consider `log_martians = 1`, but document possible log noise.
- Consider `rp_filter = 1` only after checking it does not break VPN,
  container, or multi-interface use. A looser mode may be better if Tailscale
  or complex routing becomes part of the workstation.
- Keep the current firewall stricter than the reference by default.
- Keep current resolved settings because they improve on the reference DNSSEC
  posture without making DNS strict enough to break common networks.

### Candidates To Defer

- Defer AppArmor until there is time to test expected desktop apps, browsers,
  development tools, Mango, portals, and Home Manager activation under the
  profiles NixOS provides.
- Defer fail2ban until an inbound service exists. It is not useful if there is
  nothing exposed for it to protect.
- Defer Tailscale until a concrete remote access requirement exists.
- Defer secure boot/lanzaboote adoption until the running workstation baseline
  is stable. The reference scaffold is explicitly disabled, so it is not a
  proven active configuration to copy.
- Defer auditd rules until there is a clear audit goal. Running auditd without
  a rule policy is mostly scaffolding.

### Settings Not To Copy As-Is

- Do not globally open KDE Connect ports unless KDE Connect is intentionally
  installed and used.
- Do not copy the reference `dnssec = "false"`; the current
  `DNSSEC = "allow-downgrade"` is a better workstation default.
- Do not copy the reference `configurationLimit = 3` while this repo is still
  in active migration. The current value of `5` gives better rollback coverage.
- Do not copy strict AppArmor behavior without testing. It may be useful, but
  it has a larger compatibility blast radius than the sysctl hardening.

## Suggested First Implementation Step

The safest near-term improvement is a small, explicit security module imported
by `war` and `conquest`:

```nix
{ ... }:

{
  security.protectKernelImage = true;

  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.yama.ptrace_scope" = 1;

    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
  };
}
```

Leave `rp_filter` and `log_martians` for a second pass after testing real
network behavior on `conquest`, especially if VPN, containers, or multiple
active interfaces are used.

Validation for that future implementation should include:

```console
nix fmt -- --check .
statix check .
deadnix .
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
sudo nixos-rebuild build --flake .#conquest
```

After temporary activation, verify:

```console
sysctl kernel.dmesg_restrict kernel.kptr_restrict kernel.yama.ptrace_scope
sysctl net.ipv4.conf.all.accept_redirects net.ipv6.conf.all.accept_redirects
sysctl net.ipv4.conf.all.accept_source_route net.ipv6.conf.all.accept_source_route
```

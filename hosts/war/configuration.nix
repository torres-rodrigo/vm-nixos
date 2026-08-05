{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/app-policy.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop-plasma.nix
    ../../modules/nixos/dns.nix
    ../../modules/nixos/firewall.nix
    ../../modules/nixos/hardware-intel.nix
    ../../modules/nixos/nix-maintenance.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/performance.nix
    ../../modules/nixos/storage.nix
    ../../modules/nixos/users.nix
  ];

  systemd.tmpfiles.rules = [
    "Z /etc/nixos - r users - -"
  ];

  networking.hostName = "war";

  programs.ssh.startAgent = true;

  system.stateVersion = "26.05";
}

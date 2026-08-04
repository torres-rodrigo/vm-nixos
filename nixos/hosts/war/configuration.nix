{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/firewall.nix
    ../../modules/nixos/hardware-intel.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/packages.nix
  ];

  systemd.tmpfiles.rules = [
    "Z /etc/nixos - r users - -"
  ];

  networking.hostName = "war";

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.printing.enable = true;

  users.users.r = {
    isNormalUser = true;
    description = "r";
    extraGroups = [
      "audio"
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  programs.firefox.enable = true;
  programs.ssh.startAgent = true;

  system.stateVersion = "26.05";
}

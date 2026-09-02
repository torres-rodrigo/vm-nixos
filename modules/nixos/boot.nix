{ pkgs, ... }:

{
  boot.loader = {
    timeout = 5;

    efi.canTouchEfiVariables = true;

    systemd-boot = {
      enable = true;
      configurationLimit = 5;
      editor = false;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}

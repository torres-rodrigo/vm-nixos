{ lib, pkgs, ... }:

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

  specialisation.boot-debug.configuration = {
    boot = {
      plymouth.enable = lib.mkForce false;
      kernelParams = [
        "systemd.show_status=true"
        "rd.systemd.show_status=true"
      ];
    };

    services.greetd.enable = lib.mkForce false;
    systemd.defaultUnit = "multi-user.target";
  };
}

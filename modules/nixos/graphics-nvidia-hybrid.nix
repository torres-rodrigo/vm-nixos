{
  host,
  lib,
  pkgs,
  ...
}:

let
  prime = host.nvidiaPrime or { };
  hasPrimeBusIds = (prime ? intelBusId) && (prime ? nvidiaBusId);
in
{
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;

      powerManagement = {
        enable = true;
        finegrained = hasPrimeBusIds;
      };

      prime = lib.mkIf hasPrimeBusIds {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        intelBusId = prime.intelBusId;
        nvidiaBusId = prime.nvidiaBusId;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    nvidia-settings
  ];

  warnings = lib.optional (!hasPrimeBusIds) ''
    conquest enables the NVIDIA hybrid driver, but PRIME offload is waiting for
    host.nvidiaPrime.intelBusId and host.nvidiaPrime.nvidiaBusId. On conquest,
    run: lspci | rg -i "vga|3d|display|nvidia|intel"
  '';
}

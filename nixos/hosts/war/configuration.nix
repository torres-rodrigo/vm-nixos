{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  systemd.tmpfiles.rules = [
    "Z /etc/nixos - r users - -"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "war";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Montevideo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_UY.UTF-8";
    LC_IDENTIFICATION = "es_UY.UTF-8";
    LC_MEASUREMENT = "es_UY.UTF-8";
    LC_MONETARY = "es_UY.UTF-8";
    LC_NAME = "es_UY.UTF-8";
    LC_NUMERIC = "es_UY.UTF-8";
    LC_PAPER = "es_UY.UTF-8";
    LC_TELEPHONE = "es_UY.UTF-8";
    LC_TIME = "es_UY.UTF-8";
  };

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

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.r = {
    isNormalUser = true;
    description = "r";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  programs.firefox.enable = true;
  programs.ssh.startAgent = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    lazygit
    neovim
    openssh
    wget
  ];

  system.stateVersion = "26.05";
}

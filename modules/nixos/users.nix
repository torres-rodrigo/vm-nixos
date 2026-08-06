{ pkgs, ... }:

{
  users.mutableUsers = true;

  users.users.r = {
    isNormalUser = true;
    uid = 1000;
    description = "r";
    home = "/home/r";
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "networkmanager"
      "render"
      "seat"
      "video"
      "wheel"
    ];
  };

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    shellInit = ''
      export ZDOTDIR="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    '';
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}

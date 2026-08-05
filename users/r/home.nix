{ ... }:

{
  imports = [
    ../../modules/home-manager/base.nix
  ];

  home = {
    username = "r";
    homeDirectory = "/home/r";
    stateVersion = "26.05";
  };
}

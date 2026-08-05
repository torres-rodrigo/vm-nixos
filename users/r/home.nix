{ ... }:

{
  imports = [
    ../../modules/home-manager/base.nix
    ../../modules/home-manager/files.nix
  ];

  home = {
    username = "r";
    homeDirectory = "/home/r";
    stateVersion = "26.05";
  };
}

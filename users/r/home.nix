{ ... }:

{
  imports = [
    ../../modules/home-manager/base.nix
    ../../modules/home-manager/directories.nix
    ../../modules/home-manager/files.nix
    ../../modules/home-manager/programs.nix
  ];

  home = {
    username = "r";
    homeDirectory = "/home/r";
    stateVersion = "26.05";
  };
}

{
  nixpkgs,
  home-manager,
  hostOverrides ? { },
  extraModules ? [ ],
  ...
}:

let
  inherit (nixpkgs) lib;

  baseHosts = {
    war = {
      system = "x86_64-linux";
      hostname = "war";
      username = "r";
      userHome = "/home/r";
      stateVersion = "26.05";
      configuration = ../hosts/war/configuration.nix;
      home = ../users/r/home.nix;
    };
  };

  hosts = lib.recursiveUpdate baseHosts hostOverrides;

  mkHost =
    host:
    nixpkgs.lib.nixosSystem {
      inherit (host) system;

      specialArgs = {
        inherit host;
        inherit (host) hostname username stateVersion;
      };

      modules = [
        home-manager.nixosModules.home-manager
        host.configuration
      ] ++ extraModules;
    };
in
{
  war = mkHost hosts.war;
}

{
  description = "Staged NixOS VM configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, nixpkgs, ... }:
    let
      defaultSystem = "x86_64-linux";
    in
    {
      nixosConfigurations = import ./flake/nixos-configurations.nix {
        inherit home-manager nixpkgs;
      };

      apps = import ./flake/apps.nix {
        inherit nixpkgs;
        system = defaultSystem;
      };
    };
}

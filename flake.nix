{
  description = "Staged NixOS VM configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { home-manager, nixpkgs, ... }:
    let
      defaultSystem = "x86_64-linux";
    in
    {
      nixosConfigurations = import ./flake/nixos-configurations.nix {
        inherit inputs home-manager nixpkgs;
      };

      apps = import ./flake/apps.nix {
        inherit nixpkgs;
        system = defaultSystem;
      };
    };
}

{ ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      repoPath = "/home/r/nixos/vm-nixos";
    };

    users.r = import ../../users/r/home.nix;
  };
}

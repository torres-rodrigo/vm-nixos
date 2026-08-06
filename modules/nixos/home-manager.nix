{ ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.r = import ../../users/r/home.nix;
  };
}

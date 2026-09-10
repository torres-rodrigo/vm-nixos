{ nixpkgs, system, ... }:

let
  pkgs = import nixpkgs {
    inherit system;
  };

  installNixos = pkgs.writeShellApplication {
    name = "install-nixos";

    runtimeInputs = with pkgs; [
      coreutils
      disko
      gnugrep
      gnused
      mkpasswd
      nix
      nixos-install-tools
      rsync
      systemd
      util-linux
    ];

    text = builtins.readFile ../install-nixos.sh;
  };
in
{
  ${system} = {
    install-nixos = {
      type = "app";
      program = "${installNixos}/bin/install-nixos";
      meta.description = "Install a selected NixOS host with Disko-managed LUKS2 encryption";
    };
  };
}

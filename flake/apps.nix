{ nixpkgs, system, ... }:

let
  pkgs = import nixpkgs {
    inherit system;
  };

  installEncryptedNixos = pkgs.writeShellApplication {
    name = "install-encrypted-nixos";

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

    text = builtins.readFile ../install/install-encrypted-nixos.sh;
  };
in
{
  ${system} = {
    install-encrypted-nixos = {
      type = "app";
      program = "${installEncryptedNixos}/bin/install-encrypted-nixos";
      meta.description = "Install a selected NixOS host with Disko-managed LUKS2 encryption";
    };
  };
}

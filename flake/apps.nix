{ nixpkgs, system, ... }:

let
  pkgs = import nixpkgs {
    inherit system;
  };

  installEncryptedVm = pkgs.writeShellApplication {
    name = "install-encrypted-vm";

    runtimeInputs = with pkgs; [
      coreutils
      disko
      gnugrep
      gnused
      mkpasswd
      nix
      nixos-install-tools
      rsync
      util-linux
    ];

    text = builtins.readFile ../install/install-encrypted-vm.sh;
  };
in
{
  ${system} = {
    install-encrypted-vm = {
      type = "app";
      program = "${installEncryptedVm}/bin/install-encrypted-vm";
      meta.description = "Install the war VM with Disko-managed LUKS2 encryption";
    };
  };
}

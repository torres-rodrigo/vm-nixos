{ inputs, pkgs, ... }:

let
  # The flake's default package follows the beta channel. Twilight is the
  # reproducible stable channel and exposes the zen-twilight executable.
  zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight;
  zen = pkgs.writeShellScriptBin "zen" ''
    exec ${zenBrowser}/bin/zen-twilight "$@"
  '';
in
{
  programs.firefox.enable = true;

  environment.systemPackages = [
    zenBrowser
    zen
  ];
}

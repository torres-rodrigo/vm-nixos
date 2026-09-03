{ inputs, pkgs, ... }:

let
  zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
  zen = pkgs.writeShellScriptBin "zen" ''
    exec ${zenBrowser}/bin/zen-beta "$@"
  '';
in
{
  programs.firefox.enable = true;

  environment.systemPackages = [
    zenBrowser
    zen
  ];
}

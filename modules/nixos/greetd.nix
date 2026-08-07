{
  host,
  lib,
  pkgs,
  ...
}:

let
  mangoCommand = lib.escapeShellArgs [
    "${pkgs.uwsm}/bin/uwsm"
    "start"
    "-F"
    "--"
    "/run/current-system/sw/bin/mango"
    "-c"
    "${host.userHome}/.config/mango/config.conf"
  ];

  tuigreetCommand = lib.escapeShellArgs [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--time"
    "--remember"
    "--remember-session"
    "--cmd"
    mangoCommand
  ];
in
{
  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings = {
      default_session = {
        command = tuigreetCommand;
        user = "greeter";
      };
    };
  };
}

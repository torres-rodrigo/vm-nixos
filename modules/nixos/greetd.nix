{
  host,
  lib,
  pkgs,
  username,
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
    restart = false;
    useTextGreeter = true;

    settings = {
      initial_session = {
        command = mangoCommand;
        user = username;
      };

      default_session = {
        command = tuigreetCommand;
        user = "greeter";
      };
    };
  };
}

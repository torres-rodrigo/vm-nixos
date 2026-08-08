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

  tuigreetCommand = pkgs.writeShellScript "war-tuigreet" ''
    if ${pkgs.plymouth}/bin/plymouth --ping; then
      ${pkgs.plymouth}/bin/plymouth quit || true
    fi

    exec ${lib.escapeShellArgs [
      "${pkgs.tuigreet}/bin/tuigreet"
      "--time"
      "--remember"
      "--remember-session"
      "--cmd"
      mangoCommand
    ]}
  '';
in
{
  services.greetd = {
    enable = true;
    greeterManagesPlymouth = true;
    useTextGreeter = true;

    settings = {
      default_session = {
        command = "${tuigreetCommand}";
        user = "greeter";
      };
    };
  };

  systemd.services.greetd.preStart = ''
    if ${pkgs.plymouth}/bin/plymouth --ping; then
      ${pkgs.plymouth}/bin/plymouth quit || true
    fi
  '';
}

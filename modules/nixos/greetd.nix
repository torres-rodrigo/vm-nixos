{
  host,
  lib,
  pkgs,
  ...
}:

let
  mangoConfig = "${host.userHome}/.config/mango/config.conf";

  mangoSession = pkgs.writeShellScript "war-mango-session" ''
    set -u

    state_dir="${host.userHome}/.local/state/war"
    log_file="$state_dir/mango-session.log"

    mkdir -p "$state_dir"
    touch "$log_file"
    chmod 0644 "$log_file"

    exec > >(${pkgs.coreutils}/bin/tee -a "$log_file" | ${pkgs.systemd}/bin/systemd-cat -t war-mango-session) 2>&1

    printf '=== war Mango session start: %s ===\n' "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)"
    printf 'user: '
    ${pkgs.coreutils}/bin/id
    printf 'tty: %s\n' "$(${pkgs.coreutils}/bin/tty || true)"
    printf 'XDG_RUNTIME_DIR=%s\n' "''${XDG_RUNTIME_DIR:-}"
    printf 'XDG_SESSION_TYPE=%s\n' "''${XDG_SESSION_TYPE:-}"
    printf 'WAYLAND_DISPLAY=%s\n' "''${WAYLAND_DISPLAY:-}"
    printf 'mango_config=${mangoConfig}\n'

    if [[ -e ${lib.escapeShellArg mangoConfig} ]]; then
      ${pkgs.coreutils}/bin/ls -l ${lib.escapeShellArg mangoConfig}
    else
      printf 'missing Mango config: ${mangoConfig}\n'
    fi

    if [[ -d /dev/dri ]]; then
      ${pkgs.coreutils}/bin/ls -la /dev/dri
    else
      printf '/dev/dri is missing\n'
    fi

    ${lib.escapeShellArgs [
      "${pkgs.uwsm}/bin/uwsm"
      "start"
      "-F"
      "--"
      "/run/current-system/sw/bin/mango"
      "-c"
      mangoConfig
    ]}
    status=$?
    printf 'war Mango session exited with status %s\n' "$status"
    exit "$status"
  '';

  mangoCommand = "${mangoSession}";

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
      initial_session = {
        command = mangoCommand;
        user = "r";
      };

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

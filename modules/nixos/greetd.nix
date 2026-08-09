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

    export WLR_RENDERER="''${WLR_RENDERER:-pixman}"
    export WLR_NO_HARDWARE_CURSORS="''${WLR_NO_HARDWARE_CURSORS:-1}"
    export WLR_DRM_NO_ATOMIC="''${WLR_DRM_NO_ATOMIC:-1}"

    printf 'WLR_RENDERER=%s\n' "$WLR_RENDERER"
    printf 'WLR_NO_HARDWARE_CURSORS=%s\n' "$WLR_NO_HARDWARE_CURSORS"
    printf 'WLR_DRM_NO_ATOMIC=%s\n' "$WLR_DRM_NO_ATOMIC"

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

    if [[ -z "''${XDG_RUNTIME_DIR:-}" ]]; then
      printf 'XDG_RUNTIME_DIR is not set; cannot start UWSM session\n'
      exit 1
    fi

    stop_mango() {
      trap - TERM HUP INT
      printf 'stopping wayland-wm@mango.service\n'
      ${pkgs.systemd}/bin/systemctl --user stop --wait wayland-wm@mango.service || true
      if [[ -n "''${session_pid:-}" ]]; then
        wait "$session_pid" || true
      fi
      exit 0
    }

    printf 'generating UWSM runtime units for Mango\n'
    ${lib.escapeShellArgs [
      "${pkgs.uwsm}/bin/uwsm"
      "start"
      "-o"
      "-F"
      "--"
      "/run/current-system/sw/bin/mango"
      "-c"
      mangoConfig
    ]}

    mkdir -p "$XDG_RUNTIME_DIR/uwsm"
    ${pkgs.coreutils}/bin/env -0 > "$XDG_RUNTIME_DIR/uwsm/env_login"

    printf 'binding UWSM session to wrapper PID %s\n' "$$"
    ${pkgs.systemd}/bin/systemctl --user start "wayland-session-bindpid@$$.service"

    trap stop_mango TERM HUP INT

    printf 'starting and waiting for wayland-wm@mango.service\n'
    {
      trap "" TERM HUP INT
      exec ${pkgs.systemd}/bin/systemctl --user start --wait wayland-wm@mango.service
    } &
    session_pid=$!

    wait "$session_pid"
    status=$?
    printf 'war Mango systemd session exited with status %s\n' "$status"
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

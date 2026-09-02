{
  host,
  lib,
  pkgs,
  ...
}:

let
  mangoConfig = "${host.userHome}/.config/mango/config.conf";
  isWarVm = host.hostname == "war";

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
      if ${pkgs.coreutils}/bin/ls /dev/dri/renderD* >/dev/null 2>&1; then
        printf 'render node detected\n'
      else
        printf 'no renderD node detected\n'
      fi
    else
      printf '/dev/dri is missing\n'
      exit 1
    fi

    if [[ -z "''${XDG_RUNTIME_DIR:-}" ]]; then
      printf 'XDG_RUNTIME_DIR is not set; cannot start Mango session\n'
      exit 1
    fi

    export XDG_SESSION_TYPE="wayland"

    printf 'starting Mango directly\n'
    /run/current-system/sw/bin/mango -c ${lib.escapeShellArg mangoConfig}
    status=$?
    printf 'war Mango direct session exited with status %s\n' "$status"
    exit "$status"
  '';

  mangoCommand =
    if isWarVm then
      "${mangoSession}"
    else
      lib.escapeShellArgs [
        "${pkgs.uwsm}/bin/uwsm"
        "start"
        "-N"
        "Mango WM"
        "-D"
        "mango"
        "-C"
        "Mango compositor managed by UWSM"
        "--"
        "/run/current-system/sw/bin/mango"
        "-c"
        mangoConfig
      ];

  tuigreetCommand = pkgs.writeShellScript "${host.hostname}-tuigreet" ''
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

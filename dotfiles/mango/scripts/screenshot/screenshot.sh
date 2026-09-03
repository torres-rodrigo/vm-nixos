#!/usr/bin/env bash
set -euo pipefail

mode="${1:-fullscreen}"
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/mango-screenshots"
file="$runtime_dir/screenshot-$timestamp.png"
freeze_pid=""

mkdir -p "$runtime_dir"
cleanup() {
    stop_freeze
    rm -f "$file"
}
trap cleanup EXIT

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@"
    fi
}

copy_to_clipboard() {
    if ! command -v wl-copy >/dev/null 2>&1; then
        notify "Screenshot failed" "wl-copy is not available"
        exit 1
    fi

    wl-copy --type image/png < "$file"
}

start_freeze() {
    if ! command -v wayfreeze >/dev/null 2>&1; then
        return
    fi

    wayfreeze --hide-cursor >/dev/null 2>&1 &
    freeze_pid="$!"
    sleep 0.1

    if kill -0 "$freeze_pid" 2>/dev/null; then
        return
    fi

    wayfreeze >/dev/null 2>&1 &
    freeze_pid="$!"
    sleep 0.1

    if ! kill -0 "$freeze_pid" 2>/dev/null; then
        freeze_pid=""
    fi
}

stop_freeze() {
    if [[ -n "$freeze_pid" ]]; then
        kill "$freeze_pid" 2>/dev/null || true
        wait "$freeze_pid" 2>/dev/null || true
        freeze_pid=""
    fi
}

open_in_satty() {
    if ! command -v satty >/dev/null 2>&1; then
        return
    fi

    satty \
        --filename "$file" \
        --copy-command wl-copy \
        --actions-on-enter save-to-clipboard exit \
        --actions-on-right-click save-to-clipboard \
        --actions-on-escape exit \
        --notification-thumbnail screenshot
}

case "$mode" in
    fullscreen)
        grim "$file"
        ;;
    region)
        start_freeze
        geometry="$(slurp)" || exit 0
        [[ -n "$geometry" ]] || exit 0
        grim -g "$geometry" "$file"
        stop_freeze
        ;;
    *)
        printf 'usage: %s [fullscreen|region]\n' "$0" >&2
        exit 2
        ;;
esac

copy_to_clipboard
notify "Screenshot copied" "Open Satty to annotate, or paste directly."
open_in_satty

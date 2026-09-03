#!/usr/bin/env bash
set -euo pipefail

mode="${1:-fullscreen}"
screenshot_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
file="$screenshot_dir/screenshot-$timestamp.png"

mkdir -p "$screenshot_dir"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@"
    fi
}

copy_to_clipboard() {
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy --type image/png < "$file"
    fi
}

open_in_satty() {
    if command -v satty >/dev/null 2>&1; then
        satty --filename "$file" >/dev/null 2>&1 &
    fi
}

case "$mode" in
    fullscreen)
        grim "$file"
        ;;
    region)
        geometry="$(slurp)" || exit 0
        [[ -n "$geometry" ]] || exit 0
        grim -g "$geometry" "$file"
        ;;
    *)
        printf 'usage: %s [fullscreen|region]\n' "$0" >&2
        exit 2
        ;;
esac

copy_to_clipboard
notify "Screenshot saved" "$file"
open_in_satty

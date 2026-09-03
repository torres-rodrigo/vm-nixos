#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/mango-capture"
image_file="$runtime_dir/ocr-$$.png"
freeze_pid=""

mkdir -p "$runtime_dir"

cleanup() {
    stop_freeze
    rm -f "$image_file"
}
trap cleanup EXIT

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@"
    fi
}

for cmd in slurp grim tesseract wl-copy; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify "OCR failed" "$cmd is not available"
        exit 1
    fi
done

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

start_freeze
geometry="$(slurp)" || exit 0
[[ -n "$geometry" ]] || exit 0

grim -g "$geometry" "$image_file"
stop_freeze

text="$(
    tesseract "$image_file" stdout \
        --oem 1 \
        --psm 6 \
        -l "${MANGO_OCR_LANGS:-eng}" \
        --dpi 300 \
        -c preserve_interword_spaces=1 \
        2>/dev/null
)" || {
    notify "OCR failed" "Could not extract text from the selected region."
    exit 1
}

if [[ -z "${text//[[:space:]]/}" ]]; then
    notify "OCR found no text" "Select a region with clearer text."
    exit 1
fi

printf '%s' "$text" | wl-copy
notify "OCR copied text" "Extracted text is on the clipboard."

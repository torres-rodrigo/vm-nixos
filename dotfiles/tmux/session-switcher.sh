#!/bin/sh

set -eu

kill_session() {
  target=$1
  current=$(tmux display-message -p '#S')

  if [ "$target" = "$current" ]; then
    next_session=$(
      tmux list-sessions -F '#S' |
        awk -v current="$current" '$0 != current { print; exit }'
    )

    if [ -n "$next_session" ]; then
      tmux switch-client -t "=$next_session"
      tmux kill-session -t "=$target"
    else
      tmux kill-session -t "=$target"
    fi
  else
    tmux kill-session -t "=$target"
  fi
}

if [ "${1:-}" = "--kill" ]; then
  [ -n "${2:-}" ] || exit 0
  kill_session "$2"
  exit 0
fi

current_path=${1:-$HOME}

selection=$(
  tmux list-sessions -F '#S' |
    fzf \
      --prompt='Session> ' \
      --height=100% \
      --border \
      --print-query \
      --bind='enter:accept-or-print-query' \
      --bind='ctrl-k:execute-silent(sh /etc/nixos/dotfiles/tmux/session-switcher.sh --kill {})+reload(tmux list-sessions -F "#S")+clear-query'
) || exit 0

name=$(printf '%s\n' "$selection" | tail -n 1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

[ -n "$name" ] || exit 0

case "$name" in
  *[/:.[:space:]]*)
    printf 'Invalid tmux session name: %s\n' "$name" >&2
    printf 'Use a name without spaces, /, :, or .\n' >&2
    sleep 2
    exit 1
    ;;
esac

if tmux has-session -t "=$name" 2>/dev/null; then
  tmux switch-client -t "=$name"
else
  tmux new-session -d -s "$name" -c "$current_path"
  tmux switch-client -t "=$name"
fi

#!/usr/bin/env sh
set -eu

if ! tmux list-sessions >/dev/null 2>&1; then
  tmux new-session -s MASTER
else
  latest_session="$(
    tmux list-sessions -F '#{session_created} #{session_name}' |
      sort -n |
      tail -n 1 |
      cut -d' ' -f2-
  )"

  tmux attach-session -t "=$latest_session"
fi

exec "${SHELL:-/run/current-system/sw/bin/zsh}" -l

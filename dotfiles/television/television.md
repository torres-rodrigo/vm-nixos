# Television (`tv`) Reference

Television is a fast terminal fuzzy finder. It searches live data sources, filters results interactively, previews selections, and prints selected entries to stdout for shell/script integration.

Common use cases:

- Browse files and directories.
- Search file contents interactively.
- Search git repositories, branches, logs, and history.
- Inspect environment variables, processes, Docker containers, logs, or any command output.
- Build custom searchable data sources with TOML channel files.

## Installation

Run from Nix:

```sh
nix run nixpkgs#television
```

Optional helper tools include `tldr`, `fd`, `bat`, `rg`, `docker`, and `jq`, depending on the channels you create.

## Basic Usage

```sh
tv
```

Launches the default channel, usually `files`.

```sh
tv files
tv text
tv git-repos
tv env
tv list-channels
tv update-channels
```

Built-in/common channels:

| Channel | Purpose |
| --- | --- |
| `files` | Browse files, usually backed by `fd`. |
| `text` | Search text content, usually backed by `rg`. |
| `git-repos` | Find git repositories. |
| `env` | Search environment variables. |

Channels can also be selected at runtime with remote control:

```sh
tv remote
```

Default key: `Ctrl+t`.

## Piping Data

Any command output can be piped into `tv`:

```sh
cat /var/log/syslog | tv
git log --oneline | tv
ps aux | tv
```

`tv` outputs selected entries to stdout, which makes it useful in shell commands:

```sh
vim "$(tv files)"
cd "$(tv dirs)"
cp "$(tv files)" /destination/
```

Multi-select uses `Tab`; selected entries are printed on confirmation.

```sh
nvim $(tv files)
```

## Ad-hoc Channels

Use CLI flags to create temporary channels without writing a TOML file:

```sh
tv --source-command "find . -name '*.rs'"
tv --source-command "fd -t f" --preview-command "bat -n --color=always '{}'"
tv --source-command "ls -la" --preview-command "file '{}'" --preview-size 70
```

## Search Patterns

Patterns are space-separated and combined with AND logic.

| Pattern | Match Type | Example Meaning |
| --- | --- | --- |
| `foo` | Fuzzy | Matches `foo`, `foobar`, `folder_foo`. |
| `'foo` | Exact substring | Contains literal `foo`. |
| `^foo` | Prefix | Starts with `foo`. |
| `foo$` | Suffix | Ends with `foo`. |
| `!foo` | Negation | Does not match `foo`. |

Example:

```text
test ^src !.bak$
```

Matches entries containing `test`, starting with `src`, and not ending with `.bak`.

For exact substring mode:

```sh
tv files --exact
```

This is useful for large datasets and logs where fuzzy matching is noisy or slower.

## Shell Integration

Enable shell integration:

```sh
echo 'eval "$(tv init zsh)"' >> ~/.zshrc
echo 'eval "$(tv init bash)"' >> ~/.bashrc
tv init fish | source
```

This enables:

- `Ctrl+t`: smart autocomplete based on current command.
- `Ctrl+r`: shell history search.

Shell integration config:

```toml
[shell_integration]
fallback_channel = "files"

[shell_integration.channel_triggers]
"git-branch" = ["git checkout", "git branch"]
"files" = ["cat", "less", "vim"]

[shell_integration.keybindings]
smart_autocomplete = "ctrl-t"
command_history = "ctrl-r"
```

## CLI Command Shape

```text
tv [OPTIONS] [CHANNEL] [PATH] [COMMAND]
```

Subcommands:

| Command | Purpose |
| --- | --- |
| `list-channels` | List available channels. |
| `init` | Initialize shell integration, e.g. `tv init zsh`. |
| `completions` | Generate shell tab-completion scripts. |
| `update-channels` | Download community channel prototypes. |
| `migrate-config` | Trim machine-written defaults from config. |
| `help` | Print help. |

Arguments:

| Argument | Meaning |
| --- | --- |
| `[CHANNEL]` | Channel to run. |
| `[PATH]` | Working directory; defaults to current directory. |
| `[COMMAND]` | Optional command argument. |

## Important CLI Options

Source options:

| Option | Purpose |
| --- | --- |
| `-s, --source-command <STRING>` | Override/create source command. |
| `--ansi` | Parse ANSI styling from source output. |
| `--no-sort` | Preserve source order instead of sorting by match quality/frecency. |
| `--source-display <STRING>` | Template shown in results. |
| `--source-output <STRING>` | Template printed after selection. |
| `--source-entry-delimiter <STRING>` | Custom entry delimiter, e.g. `\0`. |

Preview options:

| Option | Purpose |
| --- | --- |
| `-p, --preview-command <STRING>` | Preview command template. |
| `--preview-header <STRING>` | Preview header template. |
| `--preview-footer <STRING>` | Preview footer template. |
| `--preview-offset <STRING>` | Scroll preview to a line offset. |
| `--cache-preview` | Cache preview output; enabled by default. |
| `--no-preview` | Disable preview entirely. |
| `--hide-preview` | Hide preview initially but allow toggling. |
| `--show-preview` | Show preview initially. |
| `--preview-border <none|plain|rounded|thick>` | Preview border style. |
| `--preview-padding <STRING>` | `top=1;left=2;bottom=1;right=2`. |
| `--preview-word-wrap` | Enable preview word wrap. |
| `--hide-preview-scrollbar` | Hide preview scrollbar. |
| `--preview-size <1-99>` | Preview panel percentage. |

Input/UI options:

| Option | Purpose |
| --- | --- |
| `-i, --input <STRING>` | Prefill search input. |
| `--input-header <STRING>` | Input header template. |
| `--input-prompt <STRING>` | Prompt string. |
| `--input-position <top|bottom>` | Input position. |
| `--input-border <none|plain|rounded|thick>` | Input border. |
| `--input-padding <STRING>` | Input padding. |
| `--no-status-bar`, `--hide-status-bar`, `--show-status-bar` | Status bar controls. |
| `--results-border <none|plain|rounded|thick>` | Results border. |
| `--results-padding <STRING>` | Results padding. |
| `--layout <landscape|portrait>` | Preview beside or below results. |
| `--ui-scale <INTEGER>` | Use a percentage of terminal area. |
| `--height <INTEGER>` | Non-fullscreen height. |
| `--width <INTEGER>` | Non-fullscreen width with `--inline` or `--height`. |
| `--inline` | Inline UI at terminal bottom. |
| `--no-remote`, `--hide-remote`, `--show-remote` | Remote-control visibility. |
| `--no-help-panel`, `--hide-help-panel`, `--show-help-panel` | Help-panel visibility. |

Behavior options:

| Option | Purpose |
| --- | --- |
| `-t, --tick-rate <INT>` | UI update tick rate. |
| `--watch <FLOAT>` | Reload source every N seconds. |
| `--autocomplete-prompt <STRING>` | Guess channel from shell prompt context. |
| `--exact` | Use substring matching instead of fuzzy matching. |
| `--select-1` | Select and exit if exactly one match remains after loading. |
| `--take-1` | Wait for source load, then return first entry. |
| `--take-1-fast` | Return first entry as soon as it appears. |
| `--global-history` | Use global instead of channel-specific history. |

Keybinding/config options:

| Option | Purpose |
| --- | --- |
| `-k, --keybindings <STRING>` | Override keybindings inline. |
| `--expect <STRING>` | Additional confirmation keys; outputs the key name before selected entry. |
| `--config-file <PATH>` | Use a custom config file. |
| `--cable-dir <PATH>` | Use a custom channel directory. |

Example `--expect` usage:

```sh
output=$(tv files --expect "ctrl-e,ctrl-v")
key=$(echo "$output" | head -1)
file=$(echo "$output" | tail -1)

case "$key" in
  ctrl-e) nvim "$file" ;;
  ctrl-v) code "$file" ;;
  "") cat "$file" ;;
esac
```

## Default Keybindings

| Key | Action |
| --- | --- |
| Up/Down, `Ctrl+p`/`Ctrl+n`, `Ctrl+k`/`Ctrl+j` | Navigate results. |
| `Ctrl+Up` / `Ctrl+Down` | Previous/next history entry. |
| `PageUp` / `PageDown` | Scroll preview half page. |
| `Enter` | Confirm current entry. |
| `Tab` / `BackTab` | Toggle selection and move next/previous. |
| `Ctrl+y` | Copy selected entry to clipboard. |
| `Ctrl+r` | Reload current source. |
| `Ctrl+s` | Cycle source commands. |
| `Ctrl+f` | Cycle preview commands. |
| `Ctrl+t` | Toggle remote control. |
| `Ctrl+h` | Toggle help. |
| `Ctrl+o` | Toggle preview. |
| `F12` | Toggle status bar. |
| `Ctrl+l` | Toggle landscape/portrait layout. |
| `Ctrl+x` | Toggle action picker. |
| `Esc`, `Ctrl+c` | Quit. |

Input editing:

| Key | Action |
| --- | --- |
| `Backspace` | Delete previous character. |
| `Ctrl+w` | Delete previous word. |
| `Ctrl+u` | Delete current line. |
| `Delete` | Delete next character. |
| Left/Right | Move cursor. |
| `Home` / `End` | Move to input start/end. |
| `Ctrl+a` / `Ctrl+e` | Move to input start/end. |

## Configuration File

Television uses TOML.

Config locations:

| Platform | Path |
| --- | --- |
| Linux | `$HOME/.config/television/config.toml` |
| macOS | `$HOME/.config/television/config.toml` |
| Windows | `%LocalAppData%\television\config\config.toml` |

Environment overrides:

| Variable | Purpose |
| --- | --- |
| `TELEVISION_CONFIG` | Override config directory. |
| `TELEVISION_DATA` | Override data directory. |
| `XDG_CONFIG_HOME` | XDG config base. |
| `XDG_DATA_HOME` | XDG data base. |

General options:

| Option | Type | Default | Purpose |
| --- | --- | --- | --- |
| `tick_rate` | integer | `50` | UI update interval in milliseconds. |
| `default_channel` | string | `"files"` | Channel used when none is specified. |
| `history_size` | integer | `200` | Number of history entries; `0` disables history. |
| `global_history` | boolean | `false` | Use shared history across channels. |

UI options:

```toml
[ui]
ui_scale = 100
orientation = "landscape"
theme = "television"
```

Built-in themes:

```text
default, television, gruvbox-dark, gruvbox-light, catppuccin, nord-dark,
solarized-dark, solarized-light, dracula, monokai, onedark, tokyonight,
rose-pine, rose-pine-moon, rose-pine-dawn
```

UI component config:

```toml
[ui.input_bar]
position = "top"
prompt = ""
header = ""
border_type = "none"
padding = { left = 0, right = 0, top = 0, bottom = 0 }

[ui.results_panel]
border_type = "none"
padding = { left = 0, right = 0, top = 0, bottom = 0 }

[ui.preview_panel]
size = 50
header = "{}"
footer = ""
scrollbar = false
border_type = "none"
padding = { left = 0, right = 0, top = 0, bottom = 0 }
hidden = false

[ui.status_bar]
hidden = false

[ui.help_panel]
show_categories = true
hidden = true
disabled = false

[ui.remote_control]
show_channel_descriptions = true
sort_alphabetically = true
disabled = false
```

Theme overrides:

```toml
[ui]
theme = "gruvbox-dark"

[ui.theme_overrides]
background = "#000000"
text_fg = "#ffffff"
selection_bg = "#444444"
match_fg = "#ff0000"
```

Theme color keys:

| Area | Keys |
| --- | --- |
| General | `background`, `border_fg`, `text_fg`, `dimmed_text_fg` |
| Input | `input_text_fg`, `result_count_fg` |
| Results | `result_name_fg`, `result_line_number_fg`, `result_value_fg`, `selection_bg`, `selection_fg`, `match_fg` |
| Preview | `preview_title_fg` |
| Modes | `channel_mode_fg`, `channel_mode_bg`, `remote_control_mode_fg`, `remote_control_mode_bg`, `send_to_channel_mode_fg` |

Colors may be ANSI names such as `red`, `bright-blue`, `white`, or hex values such as `#ff0000`.

## Channels

A channel is a TOML file that defines:

- Metadata and requirements.
- Source command(s) that produce searchable entries.
- Optional preview command(s).
- Optional UI overrides.
- Keybindings and custom actions.

Channel locations:

| Platform | Path |
| --- | --- |
| Linux/macOS | `~/.config/television/cable/` |
| Windows | `%LocalAppData%\television\config\cable\` |
| Custom | `$TELEVISION_CONFIG/cable/` or `--cable-dir` |

Typical config tree:

```text
~/.config/television/
|-- config.toml
`-- cable/
    |-- files.toml
    |-- env.toml
    |-- alias.toml
    |-- git-repos.toml
    `-- text.toml
```

Minimal channel:

```toml
[metadata]
name = "my-awesome-channel"

[source]
command = "aws s3 ls my-bucket"
```

Launch:

```sh
tv my-awesome-channel
```

## Channel Specification

Top-level channel sections:

```toml
[metadata]
[source]
[preview]
[ui]
[keybindings]
[actions.NAME]
```

### `[metadata]`

| Field | Type | Required | Purpose |
| --- | --- | --- | --- |
| `name` | string | yes | Unique channel identifier. |
| `description` | string | no | Human-readable description. |
| `requirements` | string array | no | External binaries checked at runtime. |

Example:

```toml
[metadata]
name = "files"
description = "Browse and select files"
requirements = ["fd", "bat"]
```

### `[source]`

| Field | Type | Required | Purpose |
| --- | --- | --- | --- |
| `command` | string, string array, `{ name, run }`, or array | yes | Command(s) producing entries. |
| `ansi` | boolean | no | Parse ANSI escape codes. |
| `display` | string | no | Template displayed in results; incompatible with `ansi = true`. |
| `output` | string | no | Template printed after selection. |
| `watch` | float | no | Reload interval in seconds. |
| `entry_delimiter` | string | no | Entry delimiter; default is newline. |
| `no_sort` | boolean | no | Preserve source order and disable frecency. |
| `frecency` | boolean | no | Enable/disable frecency ranking. |

Examples:

```toml
[source]
command = "fd -t f"
```

```toml
[source]
command = ["fd -t f", "fd -t f -H", "fd -t f -H -I"]
```

```toml
[source]
command = [
  { name = "Default", run = "fd -t f" },
  { name = "Hidden",  run = "fd -t f -H" },
  { name = "All",     run = "fd -t f -H -I" },
]
```

```toml
[source]
command = "git log --oneline --color=always"
ansi = true
output = "{strip_ansi|split: :0}"
```

```toml
[source]
command = "docker ps --format '{{.ID}}\t{{.Names}}\t{{.Status}}'"
display = "{split:\t:1} ({split:\t:2})"
output = "{split:\t:0}"
```

```toml
[source]
command = "docker ps"
watch = 2.0
```

```toml
[source]
command = "find . -print0"
entry_delimiter = "\0"
```

Source cycling:

- Configure `command` as an array.
- Only the first command runs initially.
- Press `Ctrl+s` to cycle commands.
- Available in channel mode, not ad-hoc `--source-command` mode.

Sorting:

- `no_sort = true`: preserves source order and disables frecency.
- `frecency = false`: disables frecency while keeping match-quality sorting.
- Frecency ranks items selected often and recently higher.

### `[preview]`

| Field | Type | Required | Purpose |
| --- | --- | --- | --- |
| `command` | string or string array | no | Preview command template(s). |
| `env` | table | no | Environment variables for preview. |
| `offset` | string | no | Template for preview line offset. |
| `header` | string | no | Preview header template. |
| `footer` | string | no | Preview footer template. |

Examples:

```toml
[preview]
command = "bat -n --color=always '{}'"
```

```toml
[preview]
command = ["bat -n --color=always '{}'", "cat '{}'", "xxd '{}' | head -100"]
```

```toml
[preview]
command = "bat -n --color=always '{}'"
env = { BAT_THEME = "ansi" }
```

```toml
# Entry format: "file.txt:42:content"
[preview]
command = "bat -H '{split:\::1}' --color=always '{split:\::0}'"
offset = "{split:\::1}"
```

```toml
[preview]
command = "bat -n --color=always '{}'"
header = "File: {}"
footer = "Size: $(stat -c%s '{}')"
```

Preview cycling:

- Configure `command` as an array.
- Press `Ctrl+f` to cycle preview commands.

### Channel `[ui]`

Channel UI options mirror the global `[ui]` config and override defaults for that channel.

```toml
[ui]
ui_scale = 80
layout = "portrait"
input_bar_position = "bottom"
input_header = "Search:"
input_prompt = ">> "

[ui.preview_panel]
size = 60
header = "{}"
scrollbar = true
border_type = "rounded"
padding = { left = 1, right = 1 }
hidden = false

[ui.results_panel]
border_type = "plain"
padding = { top = 1, bottom = 1 }

[ui.input_bar]
border_type = "rounded"
padding = { left = 2, right = 2 }

[ui.status_bar]
hidden = false

[ui.help_panel]
show_categories = true
hidden = true
disabled = false

[ui.remote_control]
show_channel_descriptions = true
sort_alphabetically = true
disabled = false
```

Border options: `none`, `plain`, `rounded`, `thick`.

### Channel `[keybindings]`

```toml
[keybindings]
shortcut = "f1"
quit = ["esc", "ctrl-c"]
select_next_entry = ["down", "ctrl-j"]
select_prev_entry = ["up", "ctrl-k"]
confirm_selection = "enter"
ctrl-e = "actions:edit"
```

Keys:

- Single characters: `a`, `b`, `1`.
- Special keys: `enter`, `esc`, `tab`, `backtab`, `space`, `backspace`, `delete`, `home`, `end`, `pageup`, `pagedown`, `up`, `down`, `left`, `right`.
- Control keys: `ctrl-a`, `ctrl-b`, etc.
- Function keys: `f1` through `f12`.

Single character keys like `j` and `k` are captured as search input, so navigation should use modifier keys such as `ctrl-j`.

Multiple actions can be bound to one key:

```toml
[keybindings]
ctrl-r = ["reload_source", "copy_entry_to_clipboard"]
```

## Actions

Actions are operations that keybindings execute. Built-in actions use snake_case in config.

Navigation:

| Action | Purpose | Default Key |
| --- | --- | --- |
| `select_next_entry` | Move selection down. | Down, `Ctrl+n`, `Ctrl+j` |
| `select_prev_entry` | Move selection up. | Up, `Ctrl+p`, `Ctrl+k` |
| `select_next_page` | Move down one page. | none |
| `select_prev_page` | Move up one page. | none |

Selection:

| Action | Purpose | Default Key |
| --- | --- | --- |
| `confirm_selection` | Select current entry and exit. | `Enter` |
| `toggle_selection_down` | Toggle selection and move down. | `Tab` |
| `toggle_selection_up` | Toggle selection and move up. | `Shift+Tab` |
| `copy_entry_to_clipboard` | Copy selected entry. | `Ctrl+y` |

Input editing:

| Action | Purpose | Default Key |
| --- | --- | --- |
| `delete_prev_char` | Delete previous char. | `Backspace` |
| `delete_next_char` | Delete next char. | `Delete` |
| `delete_prev_word` | Delete previous word. | `Ctrl+w` |
| `delete_line` | Clear input. | `Ctrl+u` |
| `go_to_prev_char` | Cursor left. | Left |
| `go_to_next_char` | Cursor right. | Right |
| `go_to_input_start` | Cursor to input start. | `Home`, `Ctrl+a` |
| `go_to_input_end` | Cursor to input end. | `End`, `Ctrl+e` |

Preview:

| Action | Purpose | Default Key |
| --- | --- | --- |
| `scroll_preview_up` | Scroll preview one line up. | none |
| `scroll_preview_down` | Scroll preview one line down. | none |
| `scroll_preview_half_page_up` | Scroll preview half page up. | `PageUp` |
| `scroll_preview_half_page_down` | Scroll preview half page down. | `PageDown` |
| `cycle_previews` | Cycle preview commands. | `Ctrl+f` |

UI/channel/history/application:

| Action | Purpose | Default Key |
| --- | --- | --- |
| `toggle_preview` | Show/hide preview. | `Ctrl+o` |
| `toggle_remote_control` | Show/hide channel picker. | `Ctrl+t` |
| `toggle_help` | Show/hide help. | `Ctrl+h` |
| `toggle_status_bar` | Show/hide status bar. | `F12` |
| `toggle_layout` | Switch portrait/landscape. | `Ctrl+l` |
| `toggle_action_picker` | Show action picker. | `Ctrl+x` |
| `cycle_sources` | Cycle source commands. | `Ctrl+s` |
| `reload_source` | Reload current source. | `Ctrl+r` |
| `select_prev_history` | Previous history entry. | `Ctrl+Up` |
| `select_next_history` | Next history entry. | `Ctrl+Down` |
| `quit` | Exit. | `Esc`, `Ctrl+c` |

Reserved internal actions cannot be bound:

```text
render, resize, clear_screen, tick, suspend, resume, error, no_op
```

### Custom Actions

Custom actions live under `[actions.NAME]` and are referenced as `actions:NAME`.

| Field | Required | Purpose |
| --- | --- | --- |
| `description` | no | Human-readable action description. |
| `command` | yes | Command template to execute. |
| `mode` | no | `fork` or `execute`; default is `fork`. |
| `separator` | no | Multi-select join string; default is space. |

Modes:

| Mode | Behavior |
| --- | --- |
| `fork` | Run command in subprocess and return to `tv`. |
| `execute` | Replace `tv` with the command. |

Example:

```toml
[keybindings]
ctrl-e = "actions:edit"
ctrl-o = "actions:open"

[actions.edit]
description = "Edit file"
command = "nvim '{}'"
mode = "execute"

[actions.open]
description = "Open in default app"
command = "xdg-open '{}'"
mode = "fork"
```

Multi-select example:

```toml
[actions.edit]
description = "Open selected files in editor"
command = "nvim {split:\n:..|map:{append:'|prepend:'}|join: }"
mode = "execute"
separator = "\n"
```

## Template Syntax

Templates use a string-pipeline syntax in fields such as `display`, `output`, preview commands, headers, footers, offsets, and custom action commands.

Common patterns:

| Pattern | Purpose |
| --- | --- |
| `{}` | Entire entry. |
| `{0}`, `{1}` | Positional fields with default `:` delimiter. |
| `{split:DELIM:INDEX}` | Split by delimiter and select item/range. |
| `{strip_ansi}` | Remove ANSI escape codes. |
| `{trim}` | Trim whitespace. |
| `{upper}`, `{lower}` | Case conversion. |

Examples:

```text
"{split:,:1..3}"
# From "a,b,c,d,e" -> "b,c"

"{split:,:..|map:{trim|upper|append:!}}"
# From "  john  , jane , bob  " -> "JOHN!,JANE!,BOB!"

"{split:,:..|map:{regex_extract:\d+|pad:3:0:left}}"
# From "item1,thing22,stuff333" -> "001,022,333"

"{split:,:..|filter:\.py$|sort|map:{prepend:* }|join:\n}"
# From "app.py,readme.md,test.py,data.json" -> "* app.py\n* test.py"

"{split:,:..|map:{regex_extract://([^/]+):1|upper}}"
# From URLs -> "GITHUB.COM,GOOGLE.COM"

"{split: :..|filter:^[A-Z]|sort:desc}"
# From "apple Banana cherry Date" -> "Date,Banana"
```

## Complete Channel Examples

### TLDR Pages

Create:

```sh
mkdir -p ~/.config/television/cable
touch ~/.config/television/cable/tldr.toml
```

Channel:

```toml
[metadata]
name = "tldr"
description = "Browse and preview TLDR help pages"
requirements = ["tldr"]

[source]
command = "tldr --list"

[preview]
command = "tldr '{}'"

[ui.preview_panel]
size = 60

[keybindings]
shortcut = "f3"
ctrl-e = "actions:open"

[actions.open]
description = "Open TLDR page in pager"
command = "tldr '{}' | less"
mode = "fork"
```

Run:

```sh
tv tldr
```

### Docker Containers

```toml
[metadata]
name = "docker-containers"
description = "Manage Docker containers"
requirements = ["docker", "jq"]

[source]
command = [
  { name = "Running", run = "docker ps --format '{{.ID}}\t{{.Names}}\t{{.Status}}'" },
  { name = "All",     run = "docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}'" },
]
display = "{split:\t:1} | {split:\t:2}"
output = "{split:\t:0}"

[preview]
command = "docker inspect '{split:\t:0}' | jq ."

[ui]
layout = "landscape"

[ui.preview_panel]
size = 55
header = "Container: {split:\t:1}"

[keybindings]
shortcut = "f5"
ctrl-l = "actions:logs"
ctrl-x = "actions:stop"
ctrl-a = "actions:attach"

[actions.logs]
description = "View container logs"
command = "docker logs -f '{split:\t:0}'"
mode = "fork"

[actions.stop]
description = "Stop container"
command = "docker stop '{split:\t:0}'"
mode = "fork"

[actions.attach]
description = "Attach to container"
command = "docker exec -it '{split:\t:0}' /bin/sh"
mode = "execute"
```

### Recently Modified Files

```toml
[metadata]
name = "recent-files"
description = "Recently modified files"
requirements = ["fd", "bat"]

[source]
command = "fd -t f --changed-within 7d"

[preview]
command = "bat -n --color=always '{}'"
```

## Advanced Usage Recipes

Watch/reload live data:

```sh
tv files --watch 5.0
tv docker-ps --watch 2.0 --inline --height 10
```

Inline and fixed-size UI:

```sh
tv --inline
tv --height 15
tv --height 15 --width 80
```

Restore more visible UI chrome:

```sh
tv --input-border rounded --results-border rounded --preview-border rounded --input-prompt "> "
```

Panel visibility:

```sh
tv --hide-preview
tv --show-preview
tv --no-preview
tv --hide-status-bar
tv --show-help-panel
tv --no-remote
```

Layout:

```sh
tv --layout portrait
tv --layout landscape
```

Custom borders and padding:

```sh
tv --preview-border thick --results-border none
tv --preview-padding "top=1;left=2;bottom=1;right=2"
```

Custom source delimiter:

```sh
tv --source-command "find . -print0" --source-entry-delimiter "\0"
```

Custom config/channel directories:

```sh
tv --config-file ~/.config/television/minimal.toml
tv --cable-dir ~/my-channels/
```

Scripted selection:

```sh
tv files --input "src/" --select-1
tv files --take-1
tv files --take-1-fast
```

Combined:

```sh
tv files --preview-size 70 --expect "ctrl-e,ctrl-o" --ui-scale 80
tv files --input "config" --exact --select-1
```

## Performance Notes

- Use `--exact` for large datasets when fuzzy matching is unnecessary.
- Use `--take-1-fast` for fastest scripted first-result selection.
- Use `--no-preview` when previews are expensive or unnecessary.
- Limit source output when possible, e.g. `fd --max-results 10000`.
- Use `no_sort = true` when source order matters, such as shell history or git logs.

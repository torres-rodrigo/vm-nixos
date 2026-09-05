# Keymaps System Plan

## Goal

Create a searchable keybinding system for this NixOS workstation that can cover
Mango and application-level keymaps in one place. The system should let me find
a keybind by program name, key, description, command, context, or tag through
Television.

Omarchy is a useful reference because its `Super + K` menu stays close to the
real Hyprland bindings. The goal here is not to copy that implementation
directly. Mango, tmux, Neovim, Yazi, Lazygit, Foot, Ghostty, Television, and
other tools all expose keymaps differently, so this setup needs a broader
registry model.

Recommended direction:

1. Use a canonical keymap registry in this repo.
2. Split records by program.
3. Search records with Television.
4. Add validation so the registry does not drift silently.
5. Generate app configs from the registry only after the format proves useful.

## How Omarchy Implements `Super + K`

### Binding Declaration

Omarchy defines the `Super + K` keybinding in:

```text
/home/r/omarchy/default/hypr/bindings/utilities.lua
```

The binding is:

```lua
o.bind("SUPER + K", "Keybindings", "omarchy-menu-keybindings")
```

Related bindings in the same file:

```lua
o.bind("SUPER + ALT + K", "Tmux keybindings", "omarchy-menu-tmux-keybindings")
o.bind("SUPER + CTRL + K", "Herdr keybindings", "omarchy-menu-herdr-keybindings")
```

The important part is the `o.bind` helper. It takes:

1. key combination,
2. human description,
3. dispatcher or command,
4. optional flags.

The helper lives in:

```text
/home/r/omarchy/default/hypr/helpers.lua
```

In simplified form:

```lua
function o.bind(keys, description, dispatcher, options)
  local opts = options or {}

  if description then
    opts.description = description
  end

  dispatcher = command_from(dispatcher, description)

  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end

  hl.bind(keys, dispatcher, opts)
end
```

This is the central design trick: the description shown in the keybindings
menu is attached to the same binding declaration that Hyprland loads.

### How The Menu Gets Current Bindings

The `Super + K` command runs:

```text
/home/r/omarchy/bin/omarchy-menu-keybindings
```

That script reads live Hyprland bindings with:

```console
hyprctl binds
```

It intentionally parses the plain text output rather than JSON. The script
comments say Hyprland versions have emitted broken JSON for binds before, so
plain text was more reliable.

The live `hyprctl binds` output provides:

- modifier mask,
- key,
- keycode,
- description,
- dispatcher,
- dispatcher argument.

The menu then converts those records into display rows such as:

```text
SUPER + K                            -> Keybindings
SUPER + W / SUPER + Q                -> Close window
```

### Lua Bind Recovery

Hyprland's Lua config provider can report Lua-backed binds as:

```text
dispatcher: __lua
```

That can lose the original dispatcher metadata needed to know whether two
bindings are really alternatives for the same action.

Omarchy handles this by replaying the Lua config inside a stubbed Lua
environment. The script creates fake `hl.bind` and `hl.dsp` functions, loads:

```text
~/.config/hypr/hyprland.lua
```

and intercepts every described bind. This builds lookup maps:

- modifier mask + description -> original key,
- modifier mask + description + key -> dispatcher,
- modifier mask + description + key -> dispatcher argument.

That source-derived cache supplements the live `hyprctl binds` data.

### Keycode And Modifier Formatting

Omarchy turns numeric modifier masks into text:

| Mask | Text |
| --- | --- |
| `1` | `SHIFT` |
| `4` | `CTRL` |
| `8` | `ALT` |
| `64` | `SUPER` |
| combinations | joined modifier names |

It also resolves keycodes through:

```console
xkbcli compile-keymap
```

That makes `code:` bindings display as readable symbols. It includes fallbacks
for common keys and maps `grave` to `~`, so the menu shows the symbol printed
on the keyboard instead of an implementation name.

### Static Extra Bindings

Some bindings are not regular Hyprland binds. Omarchy adds them explicitly in
`static_bindings()`:

```text
SHIFT ALT + L -> Copy URL from Web App
SHIFT ALT + D -> Download Video from Web App
```

These come from browser-extension/native-messaging behavior rather than the
main Hyprland config.

### Alternative Chord Merging

Omarchy does not blindly merge rows with the same description. It has an
explicit allow-list:

```text
Close window
Calculator
Toggle scratchpad
Move window to scratchpad
```

Only those actions may show as alternatives on one row, and only when the
dispatcher metadata matches. This avoids hiding different actions that happen
to share a label.

Example:

```text
SUPER + W / SUPER + Q -> Close window
```

The script also refuses to merge if the combined chord text would exceed the
fixed display column.

### Caching

Omarchy caches rendered records under:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/omarchy/keybindings-<hash>.records
```

The cache key includes:

1. a manual version string, currently like `v13`,
2. active keymap lines from `hyprctl devices`,
3. full `hyprctl binds` output.

If bindings or the active keyboard layout change, the hash changes and the
menu regenerates.

The script refuses to cache an empty/broken bind result, so a failed `hyprctl`
call does not poison the cache.

### Display Surface

Omarchy displays the rows through:

```text
/home/r/omarchy/bin/omarchy-menu-select
```

That script summons the Quickshell menu in select mode, sends options through a
JSON payload, then waits on temporary files for the selected result.

For keybindings, the menu is mainly a searchable view. The records carry
dispatcher metadata too, so selecting a row can dispatch the selected binding.

### Tmux And Herdr

Omarchy uses separate commands for non-Hyprland keymaps:

```text
/home/r/omarchy/bin/omarchy-menu-tmux-keybindings
/home/r/omarchy/bin/omarchy-menu-herdr-keybindings
```

Tmux:

- starts a temporary tmux server,
- sources the selected tmux config,
- uses `tmux list-keys -aN`,
- depends on tmux key notes/descriptions,
- formats rows into a searchable menu.

Herdr:

- reads `herdr --default-config`,
- parses default key actions,
- overlays user config from `~/.config/herdr/config.toml`,
- preserves action order from defaults,
- formats records into a searchable menu.

This matters because Omarchy does not force every program through one parser.
It uses the best available source for each program.

## Why Omarchy Stays Updated

Omarchy stays updated because the Hyprland help entry is not a separate
manually maintained table. The binding declaration carries the description:

```lua
o.bind("SUPER + K", "Keybindings", "omarchy-menu-keybindings")
```

Changing the description in the binding changes what the keybinding menu sees.
Changing the binding changes live `hyprctl binds`, which changes the cache key
and regenerates the menu.

The tradeoff is that this works best for one environment where the compositor
configuration has a strong helper API. It does not automatically solve
application configs that lack descriptions or expose no resolved keymap list.

## Proposed NixOS Keymaps System

### Design Rule

Do not build the first version around scraping every config file. Parsing every
app forever is fragile because each program has a different syntax, different
defaults, and different support for descriptions.

Instead, create a canonical keymap registry. The registry becomes the searchable
source of truth. Extraction and generation can be added program by program.

First version:

1. Human-maintained registry.
2. Search with Television.
3. Validate structure and obvious conflicts.
4. Add extractors only for apps that expose reliable descriptions.

Later version:

1. Generate Mango binds from `mango.toml`.
2. Generate some tmux binds from `tmux.toml`.
3. Cross-check Neovim mappings that have `desc`.
4. Keep hard-to-generate apps as documented registry records.

### File Layout

Use one TOML file per program:

```text
dotfiles/keymaps/
  mango.toml
  tmux.toml
  neovim.toml
  yazi.toml
  lazygit.toml
  foot.toml
  ghostty.toml
  television.toml
```

This keeps merge conflicts small and makes it easy to review one app at a
time.

The generated or searchable output should not be hand-edited. Put generated
cache under:

```text
~/.cache/keymaps/
```

or produce it on demand.

### Record Schema

Each file should have a program-level header and a list of bindings:

```toml
program = "mango"
label = "Mango"
source = "dotfiles/mango/config.conf"

[[binding]]
context = "global"
key = "SUPER+SHIFT+S"
description = "Screenshot region"
command = "/home/r/.config/mango/scripts/screenshot/screenshot.sh region"
mode = "normal"
tags = ["capture", "screenshot", "clipboard"]
enabled = true
source = "dotfiles/mango/config.conf:75"
notes = "Copies the result to wl-clipboard and opens Satty for manual saving."
```

Required fields:

| Field | Meaning |
| --- | --- |
| `program` | Stable program id, such as `mango`, `tmux`, or `neovim`. |
| `label` | Human display name for the program. |
| `context` | Scope such as `global`, `normal`, `insert`, `copy-mode`, `manager`, or `terminal`. |
| `key` | Human-readable key combination. |
| `description` | Searchable action description. |
| `enabled` | Whether this binding is active and should appear by default. |

Optional fields:

| Field | Meaning |
| --- | --- |
| `command` | Command, action, function, or target invoked by the binding. |
| `mode` | Program-specific mode if `context` is not enough. |
| `tags` | Search helpers such as `window`, `capture`, `git`, `files`, `tabs`. |
| `source` | Source file and optional line number. |
| `notes` | Longer explanation or caveat. |
| `alternatives` | Other keys that intentionally do the same thing. |

Alternative chords should be explicit:

```toml
[[binding]]
context = "global"
key = "SUPER+Return"
alternatives = ["SUPER+KP_Enter"]
description = "Open terminal"
command = "foot"
enabled = true
tags = ["terminal", "launch"]
```

Do not infer alternatives only from matching descriptions.

### Search Output

The main list command should output one record per line. Recommended TSV:

```text
program<TAB>context<TAB>key<TAB>description<TAB>tags<TAB>source
```

Example:

```text
Mango	global	SUPER+SHIFT+S	Screenshot region	capture,screenshot,clipboard	dotfiles/mango/config.conf:75
Tmux	root	CTRL+1	Select window 1	window,terminal	dotfiles/tmux/tmux.conf:51
Neovim	normal	<leader>fk	Fzf Keymaps	search,keymaps	dotfiles/nvim/lua/config/keymaps.lua:292
```

Television can search all visible columns. The preview should show the full
record:

```text
Program: Mango
Context: global
Key: SUPER+SHIFT+S
Description: Screenshot region
Command: /home/r/.config/mango/scripts/screenshot/screenshot.sh region
Tags: capture, screenshot, clipboard
Source: dotfiles/mango/config.conf:75

Notes:
Copies the result to wl-clipboard and opens Satty for manual saving.
```

### Commands

Add a small command family later:

| Command | Purpose |
| --- | --- |
| `keymaps-list` | Print enabled keymap records as TSV. |
| `keymaps-list --all` | Include disabled records. |
| `keymaps-list --program mango` | Filter by program. |
| `keymaps-preview <id>` | Print full details for a record. |
| `keymaps-check` | Validate registry shape and conflicts. |
| `keymaps-tv` | Open the Television channel. |

Record IDs can be generated from:

```text
program + context + key
```

For display stability, also store an optional explicit `id` later if generated
IDs become annoying.

### Television Channel

Add a future channel:

```text
dotfiles/television/cable/keymaps.toml
```

Suggested shape:

```toml
[metadata]
name = 'keymaps'
description = 'Keymaps'
requirements = ['keymaps-list']

[source]
command = 'keymaps-list'

[preview]
command = 'keymaps-preview "{split:\t:0}"'

[keybindings]
ctrl-y = 'copy_entry_to_clipboard'
```

The exact preview command depends on whether `keymaps-list` includes a stable
record id as its first column. Prefer an ID-first TSV format for tooling:

```text
id<TAB>program<TAB>context<TAB>key<TAB>description<TAB>tags<TAB>source
```

Then the preview can use the selected ID.

User-facing command:

```console
tv keymaps
```

Optional later Mango binding:

```text
SUPER+K -> open keymaps in Television
```

Do not add that binding until the registry has useful data. The user already
said they are not interested in copying Omarchy's exact `Super + K`
functionality right now.

## Application Strategy

### Mango

Current source:

```text
dotfiles/mango/config.conf
```

First pass:

- Manually add important existing Mango binds to `dotfiles/keymaps/mango.toml`.
- Include launch, screenshot, OCR, window, layout, workspace, mouse, and gesture
  bindings.
- Keep source line references while migrating.

Later:

- Generate Mango `bind=`, `mousebind=`, `axisbind=`, and `gesturebind=` lines
  from the registry.
- Add descriptions as comments above generated groups if Mango itself does not
  support descriptions.
- Keep manual Mango config for non-keymap settings.

### Tmux

Current source:

```text
dotfiles/tmux/tmux.conf
```

Tmux supports notes through `bind-key -N`, and Omarchy uses `tmux list-keys
-aN` to display annotated bindings.

First pass:

- Add `-N` notes to important custom tmux bindings where missing.
- Mirror those records in `dotfiles/keymaps/tmux.toml`.

Later:

- Either generate bindings from the registry or validate the registry against
  `tmux list-keys -aN`.
- Keep temporary-server validation like Omarchy, because it resolves the config
  without affecting the live tmux session.

### Neovim

Current source:

```text
dotfiles/nvim/lua/config/keymaps.lua
```

Neovim mappings already support descriptions through `desc`. This makes it a
good candidate for extraction.

First pass:

- Add curated high-value records to `dotfiles/keymaps/neovim.toml`.
- Include the source file/line and mode.

Later:

- Add a Neovim headless extractor that prints mappings with `desc`.
- Use extraction as a drift check, not as the only registry source.

### Yazi

Current source:

```text
dotfiles/yazi/keymap.toml
```

Yazi keymaps already carry `desc` fields in TOML.

First pass:

- Import or mirror key bindings from `keymap.toml` into
  `dotfiles/keymaps/yazi.toml`.

Later:

- Write a parser that extracts `on`, `run`, and `desc` from Yazi TOML.
- Validate that documented Yazi records still exist.

### Lazygit

Current source:

```text
dotfiles/lazygit/config.yml
```

First pass:

- Document only custom keybindings from the `keybinding:` section.
- Avoid duplicating every Lazygit default.

Later:

- Add a YAML parser if needed.

### Foot And Ghostty

Current sources:

```text
dotfiles/foot/foot.ini
dotfiles/ghostty/config.ghostty
```

These are terminal-level bindings. Only custom or intentionally overridden
bindings should go into the registry.

First pass:

- Add copy/paste, URL mode, terminal split/tab choices, and intentionally
  unbound defaults.

Later:

- Add parser checks only if these configs grow enough to justify it.

### Television

Current sources:

```text
dotfiles/television/config.toml
dotfiles/television/cable/*.toml
```

Television has its own keybinding config and per-channel keybindings.

First pass:

- Document global Television navigation and custom per-channel bindings.
- Include the future `keymaps` channel once implemented.

Later:

- Parse `[keybindings]` tables from config and channel TOML files.

## Validation Rules

`keymaps-check` should validate:

1. Every TOML file has `program`, `label`, and at least one `[[binding]]`.
2. Every enabled binding has `context`, `key`, and `description`.
3. `program + context + key` is unique unless explicitly marked as an
   alternative or duplicate.
4. `source` paths exist when they point into this repo.
5. Descriptions are not empty placeholder text.
6. Tags are arrays of lowercase strings.
7. Disabled records are hidden from normal `keymaps-list` output.

Useful warnings:

- Same key appears in the same program but a different context.
- Same description appears multiple times without explicit alternatives.
- Source line references drift after edits.
- A registry file has no enabled bindings.

Do not fail on every repeated key globally. The same key can mean different
things in different applications.

## Implementation Phases

### Phase 1: Documentation And Registry Skeleton

1. Create this document.
2. Add `dotfiles/keymaps/README.md`.
3. Add starter registry files for Mango, tmux, Neovim, Yazi, Lazygit, Foot,
   Ghostty, and Television.
4. Manually populate the highest-value bindings first.

### Phase 2: Search

1. Add `keymaps-list`.
2. Add `keymaps-preview`.
3. Add `dotfiles/television/cable/keymaps.toml`.
4. Verify `tv keymaps` searches by program, key, description, and tags.

### Phase 3: Validation

1. Add `keymaps-check`.
2. Validate TOML shape.
3. Validate duplicate keys within a program/context.
4. Validate source paths.
5. Add the check to the normal project validation path only after it is stable.

### Phase 4: Extraction And Drift Checks

1. Add a tmux extractor using a temporary tmux server and `list-keys -aN`.
2. Add a Neovim extractor for mappings with `desc`.
3. Add a Yazi TOML extractor.
4. Compare extracted records to the registry and report drift.

### Phase 5: Generation

Only after the registry is trusted:

1. Generate Mango keybinding lines from `dotfiles/keymaps/mango.toml`.
2. Consider generating tmux bindings with `bind-key -N`.
3. Keep app-specific config hand-written where generation would reduce clarity.

## Recommended First Dataset

Start with these groups:

| Program | Groups |
| --- | --- |
| Mango | launchers, screenshots, OCR, window movement, layout switching, workspaces |
| Tmux | prefix, windows, panes, swaps, session switcher |
| Neovim | file/search pickers, LSP, diagnostics, buffers, custom plugin commands |
| Yazi | navigation, open/reveal, selection, copy/move, tabs |
| Lazygit | custom navigation and custom commands only |
| Foot | copy/paste, scrollback, URL mode, terminal spawning |
| Ghostty | intentionally unbound or custom terminal bindings |
| Television | global navigation and custom channel actions |

Do not try to document every default from every application in the first pass.
The useful target is personal/custom bindings plus defaults that are important
enough to search for.

## Final Recommendation

Adopt Omarchy's principle, not its exact implementation.

The principle is:

> Keybinding help should be generated from the same data that defines or
> validates the keybinding.

For this NixOS setup, the cleanest version is a TOML registry under
`dotfiles/keymaps/`, a `keymaps-list` command, and a Television channel. Once
that is useful, add validation and extractors. Only then consider generating
Mango or tmux config from the registry.

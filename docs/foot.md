# Foot Terminal Notes

This document tracks Foot 1.27.0 configuration options and the server/client
mode tradeoff for this Mango workstation. The active live config is
`dotfiles/foot/foot.ini`, linked by Home Manager to
`~/.config/foot/foot.ini`.

The option list below is based on the versioned template shipped with the
installed package:

```console
/nix/store/kpzvx2jhld3ckknrsa67y03gk816ln8m-foot-1.27.0/etc/xdg/foot/foot.ini
```

## Default Config

### Main

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `shell` | command; default `$SHELL` or passwd shell | Program launched in each terminal. Can include arguments. | Already set to the tmux wrapper in `dotfiles/foot/foot.ini`. |
| `term` | string; default `foot` | Sets `TERM` for child programs. | Keep default unless remote systems lack Foot terminfo. |
| `login-shell` | boolean; default `no` | Launches shell as a login shell. | Usually unnecessary because zsh config is XDG-managed. |
| `app-id` | string; default `foot` or `footclient` | Wayland app ID used by compositor rules. | Useful if Mango window rules need terminal matching. |
| `title` | string; default `foot` | Initial window title. | Low priority. |
| `locked-title` | boolean; default `no` | Prevents applications from changing the title. | Useful only if dynamic titles are annoying. |
| `font` | fontconfig list; default `monospace:size=8` | Primary and fallback fonts. | Already tuned for the laptop panel. |
| `font-bold` | fontconfig list; default derived from `font` | Custom bold font. | Useful if current bold weight looks wrong. |
| `font-italic` | fontconfig list; default derived from `font` | Custom italic font. | Optional. |
| `font-bold-italic` | fontconfig list; default derived from `font` | Custom bold italic font. | Optional. |
| `font-size-adjustment` | number, `px`, or `%`; default `0.5` | Step used by font zoom keybindings. | Tune if zoom feels too coarse or too small. |
| `include` | absolute path or `~/...`; default unset | Imports another config file. | Useful later for theme split files. |
| `line-height` | points or `px`; default font metrics | Overrides terminal cell height. | Already set for display density. |
| `letter-spacing` | points or `px`; default `0` | Adds or removes horizontal spacing between glyphs. | Already set to `1px`. |
| `horizontal-letter-offset` | points or `px`; default `0` | Moves glyphs horizontally inside cells. | Rarely needed. |
| `vertical-letter-offset` | points or `px`; default `0` | Moves glyphs vertically inside cells. | Useful only for font alignment fixes. |
| `underline-offset` | points or `px`; default font metrics | Changes underline vertical position. | Optional visual tuning. |
| `underline-thickness` | points or `px`; default font metrics | Changes underline thickness. | Optional visual tuning. |
| `strikeout-thickness` | points or `px`; default font metrics | Changes strikeout thickness. | Optional visual tuning. |
| `box-drawings-uses-font-glyphs` | boolean; default `no` | Uses font glyphs for box drawing instead of Foot's generated lines. | Keep `no` for clean TUI borders. |
| `dpi-aware` | boolean; default `no` | Sizes point fonts by monitor DPI instead of compositor scale. Pixel fonts ignore DPI sizing. | Current config uses `pixelsize`, so this matters less. |
| `gamma-correct-blending` | boolean; default `no` | Renders glyph blending in linear color space. Can look different and cost more. | Leave off for performance unless testing proves it looks better. |
| `initial-color-theme` | `dark` or `light`; default `dark` | Selects `[colors-dark]` or `[colors-light]` at startup. | Useful if light theme support is added. |
| `initial-window-size-pixels` | `WIDTHxHEIGHT`; default `700x500` | Initial floating window size in pixels. | Less important under tiling Mango. |
| `initial-window-size-chars` | `COLSxROWS`; default unset | Initial floating size in terminal cells. Mutually exclusive with pixel size. | Useful if floating terminal dimensions matter. |
| `initial-window-mode` | `windowed`, `maximized`, `fullscreen`; default `windowed` | Startup window state. | Already set to `windowed`. |
| `pad` | `XxY` or `LxTxRxB` plus centering mode; default `0x0 center-when-maximized-and-fullscreen` | Padding around the terminal grid. | Already set to `0x0` for dense tiling. |
| `resize-by-cells` | boolean; default `yes` | Constrains floating window resize to cell multiples. | Already disabled for Mango. |
| `resize-keep-grid` | boolean; default `yes` | Keeps grid dimensions stable when font size changes. | Already disabled. |
| `resize-delay-ms` | integer ms; default `100` | Delays expensive reflow while interactively resizing. | Keep default unless resize feels laggy. |
| `bold-text-in-bright` | `no`, `yes`, or `palette-based`; default `no` | Renders bold text with brighter colors. | Optional theme choice. |
| `word-delimiters` | string; default punctuation set | Controls double-click word selection boundaries. | Tune if URL/path selection feels wrong. |
| `selection-target` | `none`, `primary`, `clipboard`, `both`; default `primary` | Where mouse selection is copied automatically. | Consider `clipboard` or `both` if primary selection is not used. |
| `workers` | integer; default logical CPU count | Rendering worker thread count. `0` disables multithreading. | Worth measuring on `conquest`; too many threads may not help. |
| `utmp-helper` | path or `none`; platform default | Maintains utmp login records. | Usually leave default or disable if not needed. |
| `uppercase-regex-insert` | boolean; default `yes` | In URL/regex copy mode, uppercase hints also insert selected text into the prompt. | Niche but useful if URL copy workflows are adopted. |

### Environment

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| arbitrary `name=value` | unset by default | Adds environment variables to child processes. | Use sparingly; most environment belongs in Home Manager/session config. |

Do not set `TERM` here. Use `[main].term`.

### Security

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `osc52` | `disabled`, `copy-enabled`, `paste-enabled`, `enabled`; default `enabled` | Controls terminal escape access to the host clipboard. | Consider `copy-enabled` or `disabled` if remote SSH sessions are untrusted. |

### Bell

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `system` | boolean; default `yes` | Rings the system bell on BEL. | Could disable for a quiet workstation. |
| `urgent` | boolean; default `no` | Marks the window urgent when BEL arrives unfocused. | Useful for long-running commands. |
| `notify` | boolean; default `no` | Sends a desktop notification on BEL. | Useful with `mako`, but can be noisy. |
| `visual` | boolean; default `no` | Flashes the terminal window on BEL. | Optional accessibility signal. |
| `command` | command; default unset | Runs a custom command on BEL. | Usually unnecessary. |
| `command-focused` | boolean; default `no` | Runs `command` even when terminal is focused. | Usually leave off. |

### Desktop Notifications

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `command` | command template; default `notify-send --wait ...` | Command Foot uses for terminal-generated notifications. | Works with `mako`; customize only if activation/actions misbehave. |
| `command-action-argument` | command fragment; default `--action ${action-name}=${action-label}` | Expands action buttons for notification helpers. | Leave default unless changing notification command. |
| `close` | command or empty string; default empty | Closes existing notifications, mainly for OSC-99. Empty means Foot tries SIGINT on helper. | Low priority. |
| `inhibit-when-focused` | boolean; default `yes` | Suppresses notifications from focused Foot windows. | Sensible default. |

### Scrollback

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `lines` | integer; default `1000` | Scrollback history length. More lines use more memory. | Tune for memory versus terminal history. |
| `multiplier` | decimal; default `3.0` | Mouse wheel scroll multiplier. | Personal preference. |
| `indicator-position` | `none`, `fixed`, `relative`; default `relative` | Position indicator style while viewing scrollback. | Optional UI tuning. |
| `indicator-format` | `percentage`, `line`, or string; default empty | Text shown in scrollback indicator. | Optional UI tuning. |

### URL

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `launch` | command template; default `xdg-open ${url}` | Opens URLs selected in URL mode. | Good default because XDG portal/open policy is configured. |
| `label-letters` | string; default `sadfjklewcmpgh` | Characters used for URL jump labels. | Tune if labels feel awkward. |
| `style` | `none`, `single`, `double`, `curly`, `dotted`, `dashed`; default `dotted` | Underline style for URLs in URL mode. | Visual preference. |
| `osc8-underline` | `url-mode` or `always`; default `url-mode` | When OSC-8 hyperlinks are underlined. | Keep default unless always-visible links are desired. |
| `regex` | POSIX extended regex; default broad URL regex | Pattern used to detect URLs. | Avoid changing unless URL detection is wrong. |

### Custom Regex Sections

Custom sections are named `[regex:<id>]`.

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `regex` | POSIX extended regex | Defines text matches for a named regex mode. | Useful for custom issue IDs, file paths, or hashes. |
| `launch` | command template using `${match}` | Command run by `regex-launch`. | Useful if paired with a safe script. |

Bind custom regex actions under `[key-bindings]` with:

```ini
regex-launch=[your-id] Control+Shift+q
regex-copy=[your-id] Control+Alt+Shift+q
```

### Cursor

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `style` | usually `block`, `beam`, or `underline`; default `block` | Cursor shape. | Personal preference. |
| `blink` | boolean; default `no` | Enables cursor blinking. | Leave off for lower visual noise. |
| `blink-rate` | ms; default `500` | Cursor blink interval. | Only matters if blink is enabled. |
| `beam-thickness` | number; default `1.5` | Beam cursor thickness. | Only matters for beam cursor. |
| `underline-thickness` | number; default font underline thickness | Underline cursor thickness. | Only matters for underline cursor. |

### Mouse

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `hide-when-typing` | boolean; default `no` | Hides pointer while typing. | Useful on a laptop if pointer gets in the way. |
| `alternate-scroll-mode` | boolean; default `yes` | Sends scroll as arrow keys in alternate screen apps that do not track mouse. | Keep default for TUIs. |

### Touch

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `long-press-delay` | ms; default `400` | Delay before touch drag emulates mouse drag. | Only relevant on touch displays. |

### Colors Dark

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `alpha` | decimal `0.0`-`1.0`; default `1.0` | Window background opacity. | Already set to `0.85`. |
| `alpha-mode` | `default`, `matching`, `all`; default `default` | Controls which pixels opacity applies to. | Tune if transparency looks wrong. |
| `background` | RGB hex; default `242424` | Terminal background. | Main theme option. |
| `foreground` | RGB hex; default `ffffff` | Terminal foreground. | Main theme option. |
| `flash` | RGB hex; default `7f7f00` | Visual bell flash color. | Only if visual bell is enabled. |
| `flash-alpha` | decimal; default `0.5` | Visual bell flash opacity. | Only if visual bell is enabled. |
| `cursor` | two RGB colors or unset; default inverse fg/bg | Cursor foreground/background. | Optional theme tuning. |
| `regular0`-`regular7` | RGB hex | ANSI normal palette. | Important for theme quality. |
| `bright0`-`bright7` | RGB hex | ANSI bright palette. | Important for theme quality. |
| `dim-blend-towards` | `black` or `white`; default `black` | Direction used to auto-generate dim colors. | Theme detail. |
| `dim0`-`dim7` | RGB hex or unset | ANSI dim palette overrides. | Optional. |
| `16`-`255` | RGB hex | Overrides extended 256-color palette entries. | Rarely needed. |
| `sixel0`-`sixel15` | RGB hex | Default sixel image palette. | Useful only for sixel-heavy workflows. |
| `selection-foreground` | RGB hex or unset | Selection text color. | Optional theme tuning. |
| `selection-background` | RGB hex or unset | Selection background color. | Optional theme tuning. |
| `jump-labels` | foreground background | URL jump label colors. | Useful if URL mode is used often. |
| `scrollback-indicator` | foreground background | Scrollback indicator colors. | Optional. |
| `search-box-no-match` | foreground background | Search box colors for no match. | Optional. |
| `search-box-match` | foreground background | Search box colors for match. | Optional. |
| `urls` | RGB hex | URL underline color. | Optional. |

### Colors Light

`[colors-light]` accepts the same options as `[colors-dark]`. Its built-in
defaults match the dark section except where light theme behavior differs, such
as `dim-blend-towards=white`.

This is useful if the workstation later grows theme switching. It is not needed
for the current single dark Foot config.

### CSD

| Option | Value shape / default | What it does | Relevance here |
| --- | --- | --- | --- |
| `preferred` | `server`, `client`, or compositor-dependent value; default `server` | Chooses server-side versus client-side decorations when possible. | Mango behavior should decide this. |
| `size` | pixels; default `26` | CSD titlebar height. | Mostly irrelevant for tiled borderless use. |
| `font` | fontconfig; default primary font | Titlebar font. | Low priority. |
| `color` | RGB hex; default foreground | Titlebar text color. | Low priority. |
| `hide-when-maximized` | boolean; default `no` | Hides CSD titlebar when maximized. | Useful if floating/maximized terminals are common. |
| `double-click-to-maximize` | boolean; default `yes` | Allows titlebar double-click maximize. | Low priority under Mango. |
| `border-width` | pixels; default `0` | CSD border width. | Let Mango own borders. |
| `border-color` | RGB hex; default CSD color | CSD border color. | Low priority. |
| `button-width` | pixels; default `26` | Width of CSD buttons. | Low priority. |
| `button-color` | RGB hex; default background | Button base color. | Low priority. |
| `button-minimize-color` | RGB hex; default regular blue | Minimize button color. | Low priority. |
| `button-maximize-color` | RGB hex; default regular green | Maximize button color. | Low priority. |
| `button-close-color` | RGB hex; default regular red | Close button color. | Low priority. |

### Key Bindings

Each key binding maps an action to one or more key combinations, or `none`.
Actions with command payloads use bracket syntax such as
`pipe-visible=[command] keys`.

| Option | Default | What it does | Relevance here |
| --- | --- | --- | --- |
| `scrollback-up-page` | `Shift+Page_Up Shift+KP_Page_Up` | Scrolls up one page. | Keep. |
| `scrollback-up-half-page` | `none` | Scrolls up half a page. | Optional. |
| `scrollback-up-line` | `none` | Scrolls up one line. | Optional. |
| `scrollback-down-page` | `Shift+Page_Down Shift+KP_Page_Down` | Scrolls down one page. | Keep. |
| `scrollback-down-half-page` | `none` | Scrolls down half a page. | Optional. |
| `scrollback-down-line` | `none` | Scrolls down one line. | Optional. |
| `scrollback-home` | `none` | Jumps to top of scrollback. | Optional. |
| `scrollback-end` | `none` | Jumps to bottom of scrollback. | Optional. |
| `clipboard-copy` | `Control+Shift+c XF86Copy` | Copies selection to clipboard. | Keep for terminal convention. |
| `clipboard-paste` | `Control+Shift+v XF86Paste` | Pastes clipboard. | Keep. |
| `primary-paste` | `Shift+Insert` | Pastes primary selection. | Keep if primary selection is used. |
| `search-start` | `Control+Shift+r` | Starts scrollback search. | Useful. |
| `font-increase` | `Control+plus Control+equal Control+KP_Add` | Zooms font larger. | Useful. |
| `font-decrease` | `Control+minus Control+KP_Subtract` | Zooms font smaller. | Useful. |
| `font-reset` | `Control+0 Control+KP_0` | Resets font size. | Useful. |
| `spawn-terminal` | `Control+Shift+n` | Opens another Foot terminal. | Important if server mode is adopted. |
| `minimize` | `none` | Minimizes window. | Let Mango handle window management. |
| `maximize` | `none` | Maximizes window. | Let Mango handle window management. |
| `fullscreen` | `none` | Toggles fullscreen. | Mango already has fullscreen bindings. |
| `pipe-visible` | example command, `none` | Pipes visible terminal text to a command. | Potentially useful with picker/browser scripts. |
| `pipe-scrollback` | example command, `none` | Pipes full scrollback to a command. | Useful for search/export workflows. |
| `pipe-selected` | example command, `none` | Pipes selected text to a command. | Useful for URL/file actions. |
| `pipe-command-output` | `[wl-copy] none` | Pipes last command output to clipboard. | Worth considering with shell integration. |
| `show-urls-launch` | `Control+Shift+o` | Enters URL launch mode. | Keep. |
| `show-urls-copy` | `none` | Enters URL copy mode. | Worth binding if clipboard-first workflow matters. |
| `show-urls-persistent` | `none` | URL mode that stays active after opening. | Optional. |
| `prompt-prev` | `Control+Shift+z` | Jump to previous prompt with shell integration. | Useful if OSC-133 is added to zsh. |
| `prompt-next` | `Control+Shift+x` | Jump to next prompt with shell integration. | Useful if OSC-133 is added to zsh. |
| `unicode-input` | `Control+Shift+u` | Enters Unicode input mode. | Keep if used. |
| `color-theme-switch-1` | `none` | Switches to first color theme. | Only with theme switching. |
| `color-theme-switch-2` | `none` | Switches to second color theme. | Only with theme switching. |
| `color-theme-toggle` | `none` | Toggles dark/light theme. | Only with theme switching. |
| `noop` | `none` | Explicit no-op binding. | Useful to block defaults. |
| `quit` | `none` | Quits Foot. | Prefer Mango/window-manager close. |

### Search Bindings

These apply inside Foot scrollback search.

| Option | Default | What it does |
| --- | --- | --- |
| `cancel` | `Control+g Control+c Escape` | Cancels search. |
| `commit` | `Return KP_Enter` | Commits selected match, copying it to primary selection. |
| `find-prev` | `Control+r` | Previous match. |
| `find-next` | `Control+s` | Next match. |
| `cursor-left` | `Left Control+b` | Move cursor left. |
| `cursor-left-word` | `Control+Left Mod1+b` | Move left one word. |
| `cursor-right` | `Right Control+f` | Move cursor right. |
| `cursor-right-word` | `Control+Right Mod1+f` | Move right one word. |
| `cursor-home` | `Home Control+a` | Move to start. |
| `cursor-end` | `End Control+e` | Move to end. |
| `delete-prev` | `BackSpace` | Delete previous character. |
| `delete-prev-word` | `Mod1+BackSpace Control+BackSpace` | Delete previous word. |
| `delete-next` | `Delete` | Delete next character. |
| `delete-next-word` | `Mod1+d Control+Delete` | Delete next word. |
| `delete-to-start` | `Control+u` | Delete to start. |
| `delete-to-end` | `Control+k` | Delete to end. |
| `extend-char` | `Shift+Right` | Extend selection forward one character. |
| `extend-to-word-boundary` | `Control+w Control+Shift+Right` | Extend to word boundary. |
| `extend-to-next-whitespace` | `Control+Shift+w` | Extend to next whitespace. |
| `extend-line-down` | `Shift+Down` | Extend down one line. |
| `extend-backward-char` | `Shift+Left` | Extend backward one character. |
| `extend-backward-to-word-boundary` | `Control+Shift+Left` | Extend backward to word boundary. |
| `extend-backward-to-next-whitespace` | `none` | Extend backward to previous whitespace. |
| `extend-line-up` | `Shift+Up` | Extend up one line. |
| `clipboard-paste` | `Control+v Control+Shift+v Control+y XF86Paste` | Paste clipboard into search. |
| `primary-paste` | `Shift+Insert` | Paste primary selection into search. |
| `unicode-input` | `none` | Unicode input in search mode. |
| `scrollback-up-page` | `Shift+Page_Up Shift+KP_Page_Up` | Scroll search viewport up. |
| `scrollback-up-half-page` | `none` | Scroll up half page. |
| `scrollback-up-line` | `none` | Scroll up one line. |
| `scrollback-down-page` | `Shift+Page_Down Shift+KP_Page_Down` | Scroll search viewport down. |
| `scrollback-down-half-page` | `none` | Scroll down half page. |
| `scrollback-down-line` | `none` | Scroll down one line. |
| `scrollback-home` | `none` | Jump to scrollback start. |
| `scrollback-end` | `none` | Jump to scrollback end. |

### URL Bindings

| Option | Default | What it does | Relevance here |
| --- | --- | --- | --- |
| `cancel` | `Control+g Control+c Control+d Escape` | Leaves URL mode. | Keep. |
| `toggle-url-visible` | `t` | Shows/hides URL text in jump labels. | Keep if URL mode is used. |

### Text Bindings

`[text-bindings]` maps key combinations to raw bytes sent to the application.
The template example maps `Super+c` to `Ctrl+c`:

```ini
\x03=Mod4+c
```

This is powerful but easy to make confusing. Prefer normal Foot or Mango
bindings unless there is a specific terminal-input translation to add.

### Mouse Bindings

| Option | Default | What it does | Relevance here |
| --- | --- | --- | --- |
| `scrollback-up-mouse` | `BTN_WHEEL_BACK` | Mouse wheel scroll up. | Keep. |
| `scrollback-down-mouse` | `BTN_WHEEL_FORWARD` | Mouse wheel scroll down. | Keep. |
| `font-increase` | `Control+BTN_WHEEL_BACK` | Increase font size with mouse. | Optional. |
| `font-decrease` | `Control+BTN_WHEEL_FORWARD` | Decrease font size with mouse. | Optional. |
| `selection-override-modifiers` | `Shift` | Modifier to select text when an app grabs mouse tracking. | Keep. |
| `primary-paste` | `BTN_MIDDLE` | Middle-click primary paste. | Disable if accidental pastes are a problem. |
| `select-begin` | `BTN_LEFT` | Start normal selection. | Keep. |
| `select-begin-block` | `Control+BTN_LEFT` | Start block selection. | Useful. |
| `select-extend` | `BTN_RIGHT` | Extend selection. | Personal preference. |
| `select-extend-character-wise` | `Control+BTN_RIGHT` | Extend selection character-wise. | Optional. |
| `select-word` | `BTN_LEFT-2` | Double-click word selection. | Keep. |
| `select-word-whitespace` | `Control+BTN_LEFT-2` | Select word using whitespace boundaries. | Useful for paths. |
| `select-quote` | `BTN_LEFT-3` | Triple-click quote or row selection. | Optional. |
| `select-row` | `BTN_LEFT-4` | Quad-click row selection. | Optional. |

## Foot Server And Client Mode

### How It Works

Normal `foot` starts one terminal process per window. Each window has its own
Wayland connection, parser, font state, glyph cache, and rendering work.

Server mode starts one persistent process:

```console
foot --server
```

New windows are then opened with:

```console
footclient
```

The server owns Wayland communication, terminal parsing, and shared font/glyph
state. Each terminal window gets its own rendering threads, but input and output
are multiplexed through the server's main thread.

By default, the socket path is derived from the session:

```console
$XDG_RUNTIME_DIR/foot-$WAYLAND_DISPLAY.sock
```

If that does not exist, `footclient` falls back to less specific paths such as
`$XDG_RUNTIME_DIR/foot.sock` and `/tmp/foot.sock`.

Foot ships user systemd units:

```console
foot-server.socket
foot-server.service
```

With socket activation, only `foot-server.socket` should be enabled. The server
starts on first `footclient` connection rather than at login.

### Pros

- Faster new terminal startup because config, fonts, and glyph cache are already
  loaded.
- Lower total memory when many terminal windows are open because shared state is
  held once.
- Good fit for a terminal-heavy workflow where many Foot windows are launched
  during a session.
- Socket activation avoids starting the server until it is actually needed.

### Cons

- If the Foot server crashes, all Foot windows hosted by it close.
- Heavy output in one terminal can affect responsiveness of other Foot windows
  because input/output are multiplexed through one main thread.
- A user service may have stale or incomplete environment unless Wayland/session
  variables are imported correctly.
- `footclient` normally stays running until its terminal exits. With
  `--no-wait`, launchers return immediately, but they no longer receive the
  child exit status.
- Per-window environment can surprise you: by default, child shells inherit the
  server environment, not necessarily the `footclient` caller environment. Use
  `footclient --client-environment` when the caller's environment matters.

### Recommendation

Foot server mode is worth testing for this configuration because Foot is already
the main terminal and performance matters. It should not be enabled blindly.
The right path is a measured experiment:

1. Keep the current plain `foot` binding as a known-good fallback.
2. Add Home Manager user socket activation for Foot server.
3. Change the primary Mango terminal bind from `foot` to `footclient`.
4. Add a fallback bind or command for plain `foot`.
5. Measure startup latency, memory with one terminal, and memory with several
   terminals.
6. Keep server mode only if the many-terminal memory/startup win is worth the
   shared-failure tradeoff.

### Implementation Steps For A Future Patch

1. Add a Home Manager module such as `modules/home-manager/foot-server.nix`.
2. Install or link the packaged user units from the Foot package, or define
   equivalent `systemd.user.sockets.foot-server` and
   `systemd.user.services.foot-server`.
3. Ensure the user manager has the right Wayland environment. If needed, import
   variables during session startup:

   ```console
   systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY
   ```

4. Enable only the socket, not an always-on server service.
5. Change `dotfiles/mango/config.conf` terminal bindings:

   ```ini
   bind=SUPER,Return,spawn,footclient
   bind=SUPER,KP_Enter,spawn,footclient
   ```

6. Keep a fallback binding while testing:

   ```ini
   bind=SUPER+SHIFT,Return,spawn,foot
   ```

7. If tmux should always start, keep `shell=/home/r/.config/tmux/foot-tmux.sh`
   in `foot.ini`; both `foot` and `footclient` use the same config.
8. If launched terminals need the caller's environment, use:

   ```console
   footclient --client-environment
   ```

9. Validate with:

   ```console
   systemctl --user status foot-server.socket
   footclient
   ps -eo pid,ppid,user,comm,rss,pmem --sort=-rss
   ```

10. Roll back by restoring Mango binds to `foot` and disabling the user socket.

### Acceptance Criteria

- `footclient` opens a terminal from the Mango keybind.
- Plain `foot` fallback still works.
- New terminals start faster than plain `foot` in normal use.
- Multiple terminal windows use less combined memory than multiple standalone
  Foot processes.
- Heavy output in one terminal does not make the rest of the terminal workflow
  feel worse.
- The server survives suspend/resume and Mango reloads.

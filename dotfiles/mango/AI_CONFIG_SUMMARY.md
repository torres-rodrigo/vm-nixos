# Mango Config Summary

This file summarizes the local Mango WM setup in `config.conf` for future AI edits.
The Mango documentation is checked into `mango.wiki/`.

## Current Config Shape

- Autostart: starts `swaybg` with `~/Pictures/field_cartoon_up.png` and `noctalia`.
- Cursor: `DoomCursor`, size `32`.
- Gaps and borders: all gaps are `0`, border is `1px`, smart gaps and no-border-when-single are enabled.
- Layout defaults: new windows do not become master, master factor is `0.50`, drag-to-tile is enabled.
- Behavior: sloppy focus enabled, cursor warping disabled, animations disabled, hotarea disabled.
- Input: Caps Lock is Escape, numlock enabled, touchpad tapping/dragging enabled.
- Window rules: GTK desktop portal and common Open/Save/Print/About dialogs float.
- Launch bindings: terminal is `wezterm`, app launcher is `rofi -show drun` on Super release, browser is `firefox`, and Noctalia controls clipboard/launcher/bar.
- Media bindings: `XF86AudioLowerVolume` and `XF86AudioRaiseVolume` control volume directly; Super+Alt+Up/Down control brightness.
- Screenshot bindings: `Print` and `SUPER+SHIFT,S` call `scripts/screenshot/screenshot.sh`; screenshots are copied to clipboard first and are only saved after opening Satty from the notification. Region screenshots use `wayfreeze --hide-cursor` when installed and cleanly kill it on Escape/cancel.
- Window bindings: kill focused window, toggle fullscreen, toggle fake fullscreen, toggle floating, pin/global window, maximize-screen, and force tile layout.
- Layout bindings: direct bindings exist for `tile`, `scroller`, `monocle`, `grid`, `deck`, `center_tile`, `vertical_tile`, `right_tile`, `vertical_scroller`, `vertical_grid`, `vertical_deck`, and `tgmix`.
- Tag defaults: tags 1 through 9 use `tile`.
- Scroller tuning: single windows use full proportion, normal default proportion is `0.9`, structs is `10`, prefer center is enabled.
- Focus/navigation: stack focus, directional focus, zoom, and focus-last-window are configured.
- Swap/resize: directional window exchange, master factor resize, and floating resize bindings are configured.
- Mouse: Super+left mouse moves windows, Super+right mouse resizes windows.
- Tag navigation: Super+1 through Super+9 use `comboview`; Super+Shift sends silently; Super+Alt sends and follows.
- Overview: Super+0 toggles overview.
- Gestures: 3-finger directional focus, 4-finger tag navigation/overview.
- Scratchpad section exists but is empty.

## Documentation References

- Key dispatchers: `mango.wiki/keys.md`
- Window rules: `mango.wiki/rules.md`
- Layouts: `mango.wiki/layouts.md`
- Scratchpads: `mango.wiki/scratchpad.md`
- General config syntax: `mango.wiki/basics.md`

## Monitor Troubleshooting

Current diagnosis from `mmsg get all-monitors` and `/sys/class/drm`:

- Mango currently sees one active monitor: `DP-1` at `2560x1440`, scale `1`, position `0,0`.
- Kernel DRM currently reports `card0-DP-1: connected`.
- Kernel DRM currently reports `card0-DP-2`, `card0-DP-3`, and `card0-HDMI-A-1` as `disconnected`.
- GPU detected during troubleshooting: NVIDIA RTX 4060 Ti. If an HDMI TV is plugged into the motherboard HDMI instead of the GPU's HDMI port, Mango/NVIDIA DRM will not see it.
- Driver diagnosis: Linux is currently using `nouveau`, with `xf86-video-nouveau` installed and no `nvidia-open`/`nvidia-utils` packages installed. On this RTX 4060 Ti, the missing HDMI TV is likely a driver/EDID issue below Mango.
- Arch packages available for the current `linux` kernel: `nvidia-open` and `nvidia-utils`. Arch's NVIDIA docs recommend the NVIDIA driver stack for current supported cards, and Wayland requires NVIDIA DRM KMS (`/sys/module/nvidia_drm/parameters/modeset` should read `Y` after switching drivers).
- For an old TV on HDMI, make sure the TV is powered on and set to the correct HDMI input before starting/reloading Mango; otherwise EDID may not be reported and `HDMI-A-1` will stay disconnected.
- Because the second monitor is not reported as connected by DRM/Mango, adding Mango `monitorrule` entries alone will not make it appear.

Useful helper:

```bash
~/.config/mango/scripts/monitors/detect.sh
```

Recommended package for monitor inspection on Arch:

```bash
sudo pacman -S --needed wlr-randr
```

Once the second output appears in `mmsg get all-monitors` or `wlr-randr`, add explicit `monitorrule` lines. Keep all monitor coordinates non-negative because Mango's docs warn that negative coordinates can break XWayland click handling.

## Feature Status

| Feature | Status | Notes |
| --- | --- | --- |
| Fullscreen | Implemented | `bind=SUPER+SHIFT,f,togglefullscreen` is already present. |
| Fake fullscreen | Implemented | `bind=SUPER+CTRL,f,togglefakefullscreen` is present. |
| Window swallowing | Missing | Mango supports swallowing through `windowrule=isterm:1` on terminal windows and `noswallow:1` exclusions. |
| Window pinning | Implemented | `bind=SUPER+SHIFT,p,toggleglobal` is present. |
| Maximize screen | Implemented | `SUPER+SHIFT,x` uses `spawn_shell` to toggle maximize-screen and focused-client border rendering together. |
| Toggle last tag | Implemented | `bind=SUPER,TAB,view,-1` is present. |
| Scratchpad basics | Missing | The config has an empty scratchpad section; Mango supports `minimized`, `toggle_scratchpad`, and `restore_minimized`. |
| Screenshot basics | Implemented | Uses `grim`, `slurp`, `wl-copy`, `notify-send`, and `satty`; optionally uses `wayfreeze` for frozen region selection. |

## Recommended Additions

These are candidate lines for the remaining original wishlist items. Check key conflicts before applying.

```ini
# Standard scratchpad: hide a window, show/cycle scratchpad windows, and restore
# minimized clients. This fills the currently empty Scratchpads section.
bind=SUPER,i,minimized
bind=SUPER+ALT,i,toggle_scratchpad
bind=SUPER+SHIFT,i,restore_minimized
```

For window swallowing, add a terminal rule after confirming the terminal app ID.
Because this config launches WezTerm, likely candidates should be checked with
Mango IPC before hardcoding:

```ini
# Window swallowing: GUI apps launched from a marked terminal replace that
# terminal until the GUI app closes.
# Verify the actual WezTerm appid first.
windowrule=isterm:1,appid:wezterm

# Optional exclusions: prevent specific apps from swallowing terminals.
windowrule=noswallow:1,appid:firefox
```

Useful verification commands:

```bash
mango -c ~/.config/mango/config.conf -p
mmsg get clients
```

## Brief Feature Descriptions

- Fullscreen: makes the focused window occupy the whole output. Already bound to `SUPER+SHIFT+f`.
- Fake fullscreen: lets a client enter fullscreen-like application state without escaping the tiling layout.
- Window swallowing: lets a GUI application launched from a terminal temporarily replace that terminal window.
- Window pinning: makes a window global/sticky so it appears on every tag.
- Toggle last tag: switches back to the previous tagset, similar to last-workspace behavior.
- Standard scratchpad: hides windows into a temporary pool and brings them back on demand.

## Other Mango Features Worth Considering

These are additional built-in Mango features that are not currently configured, or are only partially covered.

| Feature | Why add it | Candidate config |
| --- | --- | --- |
| Hardware media keys | Use laptop/media keys directly instead of only Super+Alt+arrows. | See `Hardware/media keys` snippet below. |
| Screenshot bindings | Implemented. Screenshots copy to clipboard, then a notification can open Satty for saving. | Arch packages: `grim`, `slurp`, `satty`, `wl-clipboard`, `libnotify`; optional AUR package: `wayfreeze-git`. |
| Focus or move across monitors | Useful if you use more than one display; lets keyboard navigation cross outputs. | `focusmon`, `tagmon`, `focus_cross_monitor=1` |
| Floating snap and center | Makes floating/dialog windows easier to position precisely. | `enable_floating_snap=1`, `centerwin` |
| Layout cycle | Faster than remembering every direct layout key. | `circle_layout=tile,scroller,monocle,grid,deck` and `switch_layout` |
| Master count controls | Lets tile/center-tile layouts have more than one master window. | `incnmaster,+1` / `incnmaster,-1` |
| Gap controls | Temporarily add/remove gaps for readability or screenshots while keeping default gaps at `0`. | `togglegaps`, `incgaps` |
| Scroller proportion controls | Since scroller is already configured, add runtime controls for focused window width. | `switch_proportion_preset`, `set_proportion` |
| Group/tab controls | Mango supports grouping windows and moving focus inside a group. | `groupjoin`, `groupfocus`, `groupleave` |
| Overview jump mode | Adds a jump-oriented overview variant in addition to plain overview. | `togglejump` |
| Overlay toggle | Makes focused window an overlay/top-layer style window. Useful for temporary reference windows. | `toggleoverlay` |
| Toggle all visible floating | Quickly switch all visible clients between floating/tiled behavior. | `toggle_all_floating` |
| Maximize screen | Maximize focused client while keeping compositor decoration/bar behavior. | `togglemaximizescreen` |
| Cursor hiding | Hide pointer after inactivity or while typing. | `cursor_hide_timeout`, `cursor_hide_on_keypress` |
| Tag carousel/current-to-back | More workspace-like tag cycling behavior. | `tag_carousel=1`, `view_current_to_back=1` |
| Idle inhibit rules | Keep display awake for specific apps such as video players. | `windowrule=idleinhibit_when_focus:1,...` |
| Named scratchpads | App-specific dropdown windows, for example a terminal file manager or notes window. | `toggle_named_scratchpad` plus `isnamedscratchpad:1` |
| Monitor power controls | Keyboard commands to sleep/wake/toggle display power. | `sleep_toggle_monitor` |
| IPC helper binds/scripts | `mmsg` can query clients, tags, monitors, and dispatch actions from scripts. | `mmsg get all-clients`, `mmsg dispatch ...` |

## Candidate Snippets For Other Features

These are intentionally not applied to `config.conf` yet. Pick keys that match your habits and verify external tool names first.

```ini
# Hardware/media keys: works without holding Super.
bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+
bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-
bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle
bind=SHIFT,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SOURCE@ toggle
bind=NONE,XF86AudioPlay,spawn,playerctl play-pause
bind=NONE,XF86AudioNext,spawn,playerctl next
bind=NONE,XF86AudioPrev,spawn,playerctl previous
bind=NONE,XF86MonBrightnessUp,spawn,brightnessctl s +5%
bind=NONE,XF86MonBrightnessDown,spawn,brightnessctl s 5%-

# Screenshots: already implemented in config.conf. Requires grim, slurp, satty,
# notify-send from `libnotify`, and wl-copy from Arch package `wl-clipboard`.
# Optional: `wayfreeze-git` from AUR freezes the screen before region selection.
# The region path uses `wayfreeze --hide-cursor` and kills wayfreeze when slurp
# exits, so one Escape should cancel the full screenshot workflow.
bind=NONE,Print,spawn,/home/r/.config/mango/scripts/screenshot/screenshot.sh fullscreen
bind=SUPER+SHIFT,S,spawn,/home/r/.config/mango/scripts/screenshot/screenshot.sh region

# Multi-monitor keyboard control.
focus_cross_monitor=1
exchange_cross_monitor=1
bind=SUPER+CTRL,Left,focusmon,left
bind=SUPER+CTRL,Right,focusmon,right
bind=SUPER+CTRL+SHIFT,Left,tagmon,left,1
bind=SUPER+CTRL+SHIFT,Right,tagmon,right,1

# Floating quality-of-life controls.
enable_floating_snap=1
snap_distance=30
bind=SUPER+c,centerwin
bind=SUPER+SHIFT,space,toggle_all_floating
bind=SUPER+SHIFT,x,spawn_shell,mmsg dispatch togglemaximizescreen && mmsg dispatch toggle_render_border
bind=SUPER+SHIFT,o,toggleoverlay

# Layout cycling and layout tuning.
circle_layout=tile,scroller,monocle,grid,deck,center_tile
bind=SUPER+ALT,space,switch_layout
bind=SUPER+CTRL+SHIFT,h,incnmaster,-1
bind=SUPER+CTRL+SHIFT,l,incnmaster,+1
bind=SUPER+SHIFT,g,togglegaps
bind=SUPER+CTRL+SHIFT,j,incgaps,-5
bind=SUPER+CTRL+SHIFT,k,incgaps,+5

# Scroller runtime controls.
scroller_proportion_preset=0.5,0.8,0.9,1.0
bind=SUPER+ALT,s,switch_proportion_preset
bind=SUPER+ALT+SHIFT,h,set_proportion,0.5
bind=SUPER+ALT+SHIFT,l,set_proportion,1.0

# Groups/tabs.
bind=SUPER+g,groupjoin,right
bind=SUPER+SHIFT,g,groupleave
bind=SUPER+CTRL,g,groupfocus,next

# Overview jump mode.
bind=SUPER+SHIFT,0,togglejump

# Cursor hiding.
cursor_hide_timeout=5
cursor_hide_on_keypress=1

# Tag behavior.
view_current_to_back=1
tag_carousel=1

# Idle inhibit examples. Replace appids/titles after checking `mmsg get all-clients`.
windowrule=idleinhibit_when_focus:1,appid:mpv
windowrule=idleinhibit_when_focus:1,title:.*YouTube.*

# Named scratchpad example. Replace appid/title/command with a real app you use.
windowrule=isnamedscratchpad:1,width:0.80,height:0.80,appid:wezterm-scratch
bind=SUPER+ALT,Return,toggle_named_scratchpad,wezterm-scratch,none,wezterm start --class wezterm-scratch

# Monitor power example. Replace eDP-1 with the output from `mmsg get all-monitors`.
bind=SUPER+SHIFT,BackSpace,sleep_toggle_monitor,eDP-1
```

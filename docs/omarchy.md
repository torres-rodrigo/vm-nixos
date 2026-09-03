# Omarchy Adaptation Notes

## Goal And Decision Rule

This document audits the Omarchy features that are worth considering for this
NixOS Mango/Wayland workstation. Omarchy is useful as a working reference, but
it is an Arch/Hyprland system with a large integrated shell. The goal here is
not to clone it. The goal is to reuse the good interaction ideas while keeping
the NixOS system lean, explicit, and maintainable.

Performance is the main tie breaker. Prefer the smallest reliable daemon or
script for background services. Use Quickshell only where a persistent rich UI
is actually valuable, such as a bar or a detailed device panel.

## Source Map

Relevant Omarchy sources inspected:

| Area | Omarchy source | Notes |
| --- | --- | --- |
| Quickshell shell | `/home/r/omarchy/shell/plugins` | Bar, panels, clipboard UI, notifications, OSD, lock, and services are plugins in one long-running Quickshell process. |
| Clipboard | `/home/r/omarchy/shell/plugins/clipboard`, `/home/r/omarchy/bin/omarchy-clipboard-*` | Custom JSON history, image persistence, picker UI, `wl-copy`, `wl-paste`, and `wtype`. |
| Notifications | `/home/r/omarchy/shell/plugins/notifications` | Freedesktop notification server in Quickshell with DND and history. |
| Audio | `/home/r/omarchy/shell/plugins/panels/audio`, `/home/r/omarchy/bin/omarchy-audio-*` | Quickshell PipeWire service plus helper scripts using `wpctl` and `pactl`. |
| Bluetooth | `/home/r/omarchy/shell/plugins/panels/bluetooth`, `/home/r/omarchy/bin/omarchy-bluetooth-*` | Quickshell BlueZ service, pairing/connect UI, and Bluetooth audio sink handoff. |
| Network | `/home/r/omarchy/shell/plugins/panels/network`, `/home/r/omarchy/bin/omarchy-network-*` | NetworkManager panel, Wi-Fi scan/connect, DNS presets, band selection, speed tests, QR/password helpers. |
| Monitor | `/home/r/omarchy/shell/plugins/panels/monitor`, `/home/r/omarchy/bin/omarchy-hyprland-monitor-*` | Display and brightness UI; many commands assume Hyprland and `hyprctl`. |
| Calendar | `/home/r/omarchy/shell/plugins/panels/clock` | UI-only Quickshell calendar and clock formatting logic. |
| OCR and QR | `/home/r/omarchy/bin/omarchy-capture-text`, `/home/r/omarchy/bin/omarchy-capture-qr` | Region capture through `grim`/`slurp`, OCR through `tesseract`, QR through `zbarimg`. |
| Screenshots | `/home/r/omarchy/bin/omarchy-capture-screenshot`, `/home/r/omarchy/bin/omarchy-capture-region` | Rich screenshot flow with window/monitor selection, clipboard copy, save, notification, and editor launch. |
| Dictation | `/home/r/omarchy/bin/omarchy-voxtype-*`, `/home/r/omarchy/default/voxtype/config.toml` | Optional Voxtype dictation; not a general text-to-speech system. |

Current NixOS integration points:

| Area | Current source | Current state |
| --- | --- | --- |
| Wayland tools | `modules/nixos/wayland.nix` | Already installs `mako`, `grim`, `slurp`, `satty`, `wl-clipboard`, `wl-clip-persist`, and `cliphist`. |
| Audio | `modules/nixos/audio.nix` | PipeWire, WirePlumber, PulseAudio compatibility, JACK, `pamixer`, and low-latency tuning. |
| Network | `modules/nixos/networking.nix` | NetworkManager enabled with iwd backend. |
| Mango config | `dotfiles/mango/config.conf` | Live-editable Mango config with basic launch, audio, brightness, and screenshot bindings. |
| Screenshot script | `dotfiles/mango/scripts/screenshot/screenshot.sh` | Simple `grim`/`slurp` script that saves, copies to clipboard, notifies, and opens `satty`. |

## Feature Audit

### Quickshell And Panels

Omarchy approach:

Omarchy runs a single long-lived Quickshell process called `omarchy-shell`.
That process owns the top bar, panels, notifications, clipboard picker, OSD,
lock screen, polkit dialog, and small background services. The benefit is a
very cohesive UI: panels open instantly, share theme state, and communicate
inside one process.

The cost is that many independent desktop concerns become coupled to one large
QML process. A crash or leak in the shell can affect notifications, panels,
clipboard UI, OSD, and lock UI at once. It also brings Qt/QML runtime cost
even for features that can be handled by small command-line tools.

Recommendation:

Use Quickshell selectively. It is worth evaluating for a rich bar with panels,
but it should not be the default owner of clipboard history, notifications, or
simple key actions. Start with lightweight services and scripts; add
Quickshell panels only for interactions where the UI quality justifies the
resident process.

Basic NixOS adaptation:

1. Add `pkgs.quickshell` only in a future optional UI module, not the base
   Wayland module.
2. Keep the Quickshell configuration under `dotfiles/quickshell` while actively
   iterating, linked by Home Manager in `modules/home-manager/files.nix`.
3. Make it a user service or Mango `exec-once` only after the shell can start
   cleanly on both `war` and `conquest`.
4. If adopted, start with clock/calendar plus read-only status widgets before
   adding mutating panels such as Bluetooth or network controls.

### Monitor, Display, And Brightness

Omarchy approach:

The monitor panel exposes brightness, text size, scale presets, and display
enable/disable controls. It uses QML for the UI, helper scripts for hardware
operations, and Hyprland-oriented commands for display state. The scripts and
panel expect Hyprland concepts such as focused monitor, monitor JSON, and
`hyprctl`.

Recommendation:

Do not port this one directly. Mango compatibility is the hard boundary. Keep
simple brightness keys through `brightnessctl` first. For display layout,
prefer Mango-native commands if available; use `wlr-randr` only for basic
Wayland output inspection/control where it works.

Basic NixOS adaptation:

1. Keep `brightnessctl` in `modules/nixos/packages.nix`; current Mango bindings
   already use it.
2. Use `wlr-randr` from `modules/nixos/wayland.nix` for manual inspection.
3. Create a small Mango-specific display helper only after the needed Mango
   command interface is confirmed.
4. If Quickshell is adopted later, build a Mango-native monitor panel rather
   than copying Omarchy's Hyprland-specific scripts.

### Bluetooth

Omarchy approach:

The Bluetooth panel uses `Quickshell.Bluetooth` for live adapter/device state.
It groups connected, paired, and discovered devices; starts discovery while
the panel is open; tracks pending connect/disconnect/forget actions; and uses
PipeWire state to switch the default audio sink when a Bluetooth audio device
connects.

Recommendation:

Adopt the system plumbing, not necessarily the panel first. Bluetooth is useful
on `conquest`, but the first NixOS step should be small: enable BlueZ and add a
minimal command/UI path. The Quickshell panel can come later if Bluetooth
device switching is a frequent workflow.

Basic NixOS adaptation:

1. Add a focused NixOS Bluetooth module with `hardware.bluetooth.enable = true`
   and `services.blueman.enable = true` only if a GUI tray/control tool is
   acceptable.
2. For a leaner setup, skip Blueman and use `bluetoothctl` plus keybound helper
   scripts.
3. Keep Bluetooth audio policy in PipeWire/WirePlumber; Omarchy's A2DP
   autoconnect idea is worth reviewing if headset switching is unreliable.
4. If a Quickshell panel is added, port only the UI logic and replace
   Omarchy-specific helper names with Nix-managed scripts.

### Wi-Fi And Network

Omarchy approach:

Omarchy uses NetworkManager and drives it through the Quickshell network
service plus `nmcli`, `iw`, and helper scripts. The panel supports scanning,
connecting, disconnecting, Wi-Fi radio toggle, DNS presets, captive portal
state, band selection, speed tests, Wi-Fi QR generation, and password display.

Current NixOS differs in one important way: NetworkManager is enabled, but its
Wi-Fi backend is `iwd`. Omarchy's current hardware setup retires standalone
iwd state and uses NetworkManager directly. This does not block reuse, but
commands that assume NetworkManager owns all Wi-Fi details need testing against
the configured backend.

Recommendation:

Keep NetworkManager as the base. Reuse Omarchy's small `nmcli` ideas
incrementally, especially Wi-Fi status, band display, and QR generation. Delay
the full Quickshell network panel until the Mango session has a stable bar.

Basic NixOS adaptation:

1. Keep `networking.networkmanager.enable = true`.
2. Confirm whether `wifi.backend = "iwd"` remains desired for performance and
   reliability on `conquest`.
3. Add `iw`, `qrencode`, and any network helper packages only when their
   scripts are added.
4. Start with command helpers for status and QR/password display before adding
   a persistent network panel.
5. Treat password display as sensitive: do not notify or log secrets.

### Sound, Volume, And Microphone

Omarchy approach:

Omarchy's audio panel uses `Quickshell.Services.Pipewire` for live default
sink/source, nodes, playback streams, and MPRIS matching. Helper scripts use
`wpctl` and `pactl` for default device changes, mute, and volume control. The
microphone widget indicates mute state and active capture streams.

Recommendation:

Use the lightweight command path first. This NixOS repo already has a stronger
PipeWire baseline in `modules/nixos/audio.nix`. Basic volume and microphone
actions do not require Quickshell. A Quickshell audio panel is useful only if
per-app stream mixing and device switching from the bar become daily workflows.

Basic NixOS adaptation:

1. Keep PipeWire and WirePlumber in `modules/nixos/audio.nix`.
2. Prefer `wpctl` for default sink/source and mute actions; `pactl` is still
   acceptable for PulseAudio-compatible volume commands.
3. Add Mango keybindings for:
   - output volume up/down,
   - output mute,
   - microphone mute,
   - optional 1 percent precise volume steps.
4. Use `pwvucontrol` for a full GUI mixer before carrying a custom panel.
5. If Quickshell is adopted, port audio after the bar is stable and keep helper
   scripts Nix-managed.

### Calendar

Omarchy approach:

The clock/calendar is a Quickshell panel. Most of the date math is pure
JavaScript: clock formats, ISO week numbers, week start handling, month grid,
year progress, and optional life progress.

Recommendation:

This is one of the safer Quickshell pieces to reuse because it is UI-only and
does not own system state. If a Quickshell bar is adopted, calendar is a good
early widget. Without a Quickshell bar, keep time/date simple.

Basic NixOS adaptation:

1. Do nothing until a bar decision exists.
2. If using Quickshell, port clock/calendar before mutating panels.
3. Keep week-start and clock-format settings in user config/state, not system
   Nix options.

### Clipboard Management

Omarchy approach:

Omarchy implements its own clipboard history. `wl-paste` captures clipboard
changes and emits JSON entries. Text entries go into
`~/.local/state/omarchy/clipboard-history.json`. Image entries are written into
`~/.local/state/omarchy/clipboard-images` and deduplicated by hash. The picker
is a Quickshell overlay that searches text/images and can copy, paste, or open
entries. It handles sensitive clipboard state and KDE password-manager hints
by skipping history.

It also uses `wtype` to paste selected entries with `Shift+Insert`. That is a
nice compatibility trick, but it adds another moving part.

Recommendation:

Prefer `wl-clipboard` plus `cliphist` for the baseline. It is the smaller,
standard Wayland approach and is already installed in `modules/nixos/wayland.nix`.
Only consider Omarchy's custom clipboard if image previews, custom open actions,
or a unified Quickshell picker are important enough to carry custom state code.

Basic NixOS adaptation:

1. Keep `wl-clipboard`, `wl-clip-persist`, and `cliphist` in the Wayland module.
2. Add a user service or Mango `exec-once` for clipboard watching only when the
   desired history behavior is chosen.
3. Use a lightweight picker command first, for example `cliphist list` piped
   into an existing picker and decoded back to `wl-copy`.
4. Mark sensitive copies with `wl-copy --sensitive` for QR/secrets workflows.
5. Do not store clipboard history under `dotfiles/`; it belongs under XDG state.

### Notifications

Omarchy approach:

Omarchy implements a Freedesktop notification server in Quickshell. It handles
toast display, DND, notification history, images, actions, replacement updates,
and persistent popup/history files under XDG state. The implementation is
careful, but it is also a lot of custom logic inside the same shell process as
the rest of the desktop UI.

Recommendation:

Use `mako` first. It is a focused notification daemon and already present in
`modules/nixos/wayland.nix`. The Omarchy approach is attractive only if
notification history, themed action cards, and tight bar integration become
more important than having a simple independent daemon.

Basic NixOS adaptation:

1. Keep `mako` as the notification baseline.
2. Add a minimal Home Manager or store-managed Mako config if styling or DND
   behavior needs to be explicit.
3. Start Mako from Mango `exec-once` or a user service, but avoid duplicating
   notification servers.
4. If Quickshell notifications are later adopted, remove/disable Mako in the
   same change.

### Dictation, Text To Speech, And Speech Tools

Omarchy approach:

Omarchy provides optional Voxtype dictation, not general text-to-speech
generation. The installer adds `wtype` and `voxtype-bin`, copies
`~/.config/voxtype/config.toml`, downloads a Whisper model, optionally enables
GPU support, and installs a user systemd service. Default config uses
`base.en`, 16 kHz audio, max 60 second recordings, MPRIS pause while recording,
and output by simulated typing with clipboard fallback.

No general TTS flow was found in the inspected Omarchy sources.

Recommendation:

Treat dictation as optional and model-heavy. It should not be in the base
Wayland profile. Add it only after confirming Nix packaging for Voxtype or
choosing an alternative. For actual TTS, evaluate a separate tool such as
Piper or eSpeak-ng in a later task; do not conflate it with Omarchy's dictation.

Basic NixOS adaptation:

1. Do not add Voxtype to the base module.
2. Check whether `voxtype` or `voxtype-bin` is available in the selected
   nixpkgs or needs a package override.
3. If added, make it an optional Home Manager user service and keep models in
   user data/state, not in the repository.
4. Bind push-to-talk and toggle keys in Mango only when the service exists.
5. Prefer clipboard output if simulated typing proves unreliable or expensive.

### OCR And Image Text Extraction

Omarchy approach:

`omarchy-capture-text` freezes the screen with `hyprpicker`, selects a region
with `slurp`, captures it with `grim`, runs Tesseract, copies the recognized
text to the clipboard, and sends a notification. It uses:

```console
grim -g "$SELECTION" - | tesseract stdin stdout --oem 1 --psm 6 -l "${OMARCHY_OCR_LANGS:-eng}" --dpi 300 -c preserve_interword_spaces=1
```

The `hyprpicker` freeze step is Hyprland-specific convenience. The essential
portable pipeline is `slurp -> grim -> tesseract -> wl-copy`.

Recommendation:

Adopt this feature. It is script-based, on-demand, and has no idle cost. Skip
the Hyprland-specific freeze until a Mango-compatible freeze method exists.

Basic NixOS adaptation:

1. Add `tesseract` and needed language data to a focused capture/OCR package
   set, not the broad base, unless OCR becomes a core daily tool.
2. Create a Mango script under `dotfiles/mango/scripts/capture/ocr.sh`.
3. Implement region selection with `slurp`, capture with `grim`, OCR with
   `tesseract`, and copy with `wl-copy`.
4. Add `OMARCHY_OCR_LANGS`-style configuration only if more than English is
   needed; use a project-specific variable name if preferred.
5. Notify only success/failure, not the extracted text.

### QR Capture

Omarchy approach:

`omarchy-capture-qr` is similar to OCR but uses `zbarimg`. It disables all
barcode symbologies except QR to avoid false positives. It copies the result
with `wl-copy --sensitive` and does not print or notify the decoded value.

Recommendation:

Adopt this security pattern directly if QR capture is added. It is on-demand
and avoids retaining secrets in clipboard history.

Basic NixOS adaptation:

1. Add `zbar` only when the QR script is added.
2. Use `slurp`, `grim`, `zbarimg -q --raw -Sdisable -Sqrcode.enable -`, and
   `wl-copy --sensitive`.
3. Never put QR content in notifications, logs, or shell output.

### Screenshots

Omarchy approach:

Omarchy has a polished screenshot flow. It supports smart, region, window, and
fullscreen modes; saves to the pictures directory; copies the image to the
clipboard; sends a thumbnail notification; and opens an editor such as Tensaku.
The region picker is sophisticated but heavily Hyprland-oriented: it reads
monitors and clients through `hyprctl`, freezes the screen through Hyprland
tools, and has scoped Hyprland keybindings while `slurp` is open.

Current NixOS already has a simpler Mango script:

```console
dotfiles/mango/scripts/screenshot/screenshot.sh fullscreen
dotfiles/mango/scripts/screenshot/screenshot.sh region
```

It uses `grim`, `slurp`, `wl-copy`, `notify-send`, and `satty`.

Recommendation:

Keep the current script as the baseline and improve it incrementally. Porting
Omarchy's full smart/window picker is not a first step because it depends on
Hyprland client and monitor APIs. The direct Omarchy ideas worth keeping are:
save plus clipboard by default, configurable output directory, annotation
editor hook, and careful handling of cancellation.

Basic NixOS adaptation:

1. Keep `grim`, `slurp`, `wl-clipboard`, `libnotify`, and `satty`.
2. Add modes only when Mango exposes enough window/monitor information.
3. Add environment variables for screenshot directory and editor if needed.
4. Keep screenshot files under `Pictures/Screenshots` or XDG pictures, not the
   repository.
5. Consider `gpu-screen-recorder` separately for video capture; it is larger
   and should be optional.

## Recommended NixOS Adaptation Order

1. Keep the existing lightweight screenshot path and add OCR/QR scripts. These
   are on-demand and have no idle process cost.
2. Add explicit Mako startup/config if notifications are not already started
   reliably by the Mango session.
3. Add clipboard history with `cliphist` and a small picker command before
   considering Omarchy's Quickshell clipboard UI.
4. Add audio and microphone keybindings around `wpctl`/`pactl`; rely on
   `pwvucontrol` for full mixing.
5. Add Bluetooth system support on `conquest`, initially with `bluetoothctl` or
   Blueman depending on desired idle footprint.
6. Add small NetworkManager helpers for Wi-Fi status, QR, and band inspection.
7. Evaluate Quickshell as an optional bar/panel layer. Start with clock/calendar
   and read-only status widgets before mutating panels.

## Package And Module Checklist

Already present:

| Package/tool | Source | Keep for |
| --- | --- | --- |
| `grim` | `modules/nixos/wayland.nix` | Screenshots, OCR, QR capture. |
| `slurp` | `modules/nixos/wayland.nix` | Region selection. |
| `satty` | `modules/nixos/wayland.nix` | Screenshot annotation. |
| `wl-clipboard` | `modules/nixos/wayland.nix` | Clipboard read/write. |
| `wl-clip-persist` | `modules/nixos/wayland.nix` | Clipboard persistence. |
| `cliphist` | `modules/nixos/wayland.nix` | Lightweight clipboard history candidate. |
| `mako` | `modules/nixos/wayland.nix` | Lightweight notification server. |
| `libnotify` | `modules/nixos/wayland.nix` | `notify-send`. |
| `pamixer` | `modules/nixos/audio.nix` | Audio control. |
| `pwvucontrol` | `modules/nixos/audio.nix` | Full PipeWire GUI mixer. |
| `brightnessctl` | `modules/nixos/packages.nix` | Backlight control. |

Candidate additions:

| Package/tool | Add when | Notes |
| --- | --- | --- |
| `tesseract` plus language data | OCR script is added | Start with English only unless more languages are needed. |
| `zbar` | QR capture is added | Use QR-only decode mode and sensitive clipboard. |
| `wtype` | Dictation or paste simulation is added | Avoid unless needed. |
| `quickshell` | Bar/panel experiment starts | Keep optional until stable. |
| `bluez`/Bluetooth NixOS options | Bluetooth is enabled on `conquest` | Prefer NixOS service options over package-only setup. |
| `qrencode` | Wi-Fi QR generation is added | For sharing current Wi-Fi network. |
| `iw` | Wi-Fi band/status helpers are added | Current udev rule already references `pkgs.iw`; expose command if scripts need it. |
| `gpu-screen-recorder` | Screen recording is explicitly requested | Larger feature; keep separate from screenshots. |
| `voxtype` or alternative dictation package | Dictation is explicitly requested | Verify Nix availability first. |
| `piper` or `espeak-ng` | General TTS is requested | Not found as an Omarchy feature in inspected sources. |

## Open Follow-Up Measurements

Before adopting Quickshell, measure:

```console
ps -eo pid,ppid,user,comm,rss,pmem --sort=-rss
nix path-info --no-write-lock-file -S nixpkgs#quickshell
nix path-info --no-write-lock-file -r nixpkgs#quickshell | wc -l
```

Before replacing Mako with Quickshell notifications, measure current Mako idle
RSS and confirm no second notification server is running.

Before adding dictation, measure model size, idle service RSS, and transcription
latency on `conquest`, with and without GPU acceleration if supported.

Before porting Omarchy monitor or screenshot smart selection, confirm the Mango
command interface for focused monitor, output geometry, and client/window
geometry. Do not copy the Hyprland `hyprctl` path into this repo.

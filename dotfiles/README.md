# Dotfiles

This directory is reserved for explicitly live-editable configuration sources.

Home Manager owns the symlink into `$HOME`; this repository owns the source
file under `dotfiles/`. On the VM, live links currently point to
`/etc/nixos/dotfiles`, so the checkout used for rebuilds should live at
`/etc/nixos`.

A rebuild is needed when adding, removing, or changing a Home Manager link
declaration. Edits to an already-linked file are read live by the application
when it reloads or rereads the file.

Current live-managed files:

- `dotfiles/zsh/.zshenv` -> `~/.config/zsh/.zshenv`
- `dotfiles/zsh/.zshrc` -> `~/.config/zsh/.zshrc`
- `dotfiles/fzf/fzf` -> `~/.config/fzf/fzf`
- `dotfiles/lazygit/config.yml` -> `~/.config/lazygit/config.yml`
- `dotfiles/mango/config.conf` -> `~/.config/mango/config.conf`
- `dotfiles/television/config.toml` -> `~/.config/television/config.toml`
- `dotfiles/television/cable` -> `~/.config/television/cable`
- `dotfiles/wezterm/wezterm.lua` -> `~/.config/wezterm/wezterm.lua`
- `dotfiles/yazi` -> `~/.config/yazi`

Starship and Git are store-managed through Home Manager modules instead of
live-linked. The zsh files live under `~/.config/zsh`; NixOS sets `ZDOTDIR`
globally so zsh reads that directory.

Explicitly managed live files are forced during activation. Existing files at
those target paths are replaced by the repository-owned version, so do not keep
unique machine-local edits only in `$HOME`.

Do not store secrets, generated application state, caches, or files rewritten
unpredictably by applications here.

# ── XDG Base Directories ──────────────────────────────────────────────────────
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

mkdir -p "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME/zsh"

# ── Rust ──────────────────────────────────────────────────────────────────────
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

# ── Go ────────────────────────────────────────────────────────────────────────
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"

# ── Zig ───────────────────────────────────────────────────────────────────────
export ZIG_GLOBAL_CACHE_DIR="$XDG_CACHE_HOME/zig"
export ZIG_GLOBAL_PACKAGE_DIR="$XDG_DATA_HOME/zig"

# ── .NET ──────────────────────────────────────────────────────────────────────
export NUGET_PACKAGES="$XDG_CACHE_HOME/nuget"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export DOTNET_CLI_CACHE_HOME="$XDG_CACHE_HOME/dotnet"

# ── Odin ──────────────────────────────────────────────────────────────────────
export ODIN_ROOT="$XDG_DATA_HOME/odin"
export OLS_BUILTIN_FOLDER="$XDG_DATA_HOME/src/ols/builtin"

# ── Starship ──────────────────────────────────────────────────────────────────
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# ── Fzf ───────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git --no-ignore'
export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/fzf/fzf"

# ── Less ──────────────────────────────────────────────────────────────────────
export LESSHISTFILE="-"

# ── XCursor ───────────────────────────────────────────────────────────────────
export XCURSOR_PATH="$XDG_DATA_HOME/icons"

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$CARGO_HOME/bin:$GOPATH/bin:$ODIN_ROOT:$PATH"

# ── Gaming ────────────────────────────────────────────────────────────────────
# Prefer native Wayland for SDL games; fall back to X11 via XWayland
export SDL_VIDEODRIVER="wayland,x11"
# Scale OpenMP thread count to all available CPU cores
export OMP_NUM_THREADS="$(nproc)"

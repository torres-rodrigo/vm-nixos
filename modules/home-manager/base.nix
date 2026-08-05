{ ... }:

{
  home = {
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      CARGO_HOME = "$XDG_DATA_HOME/cargo";
      RUSTUP_HOME = "$XDG_DATA_HOME/rustup";

      GOPATH = "$XDG_DATA_HOME/go";
      GOMODCACHE = "$XDG_CACHE_HOME/go/mod";

      ZIG_GLOBAL_CACHE_DIR = "$XDG_CACHE_HOME/zig";
      ZIG_GLOBAL_PACKAGE_DIR = "$XDG_DATA_HOME/zig";

      NUGET_PACKAGES = "$XDG_CACHE_HOME/nuget";
      DOTNET_CLI_HOME = "$XDG_CONFIG_HOME/dotnet";
      DOTNET_CLI_CACHE_HOME = "$XDG_CACHE_HOME/dotnet";

      ODIN_ROOT = "$XDG_DATA_HOME/odin";
      OLS_BUILTIN_FOLDER = "$XDG_DATA_HOME/src/ols/builtin";

      STARSHIP_CONFIG = "$XDG_CONFIG_HOME/starship/starship.toml";

      FZF_DEFAULT_COMMAND = "fd --hidden --follow --exclude .git --no-ignore";
      FZF_DEFAULT_OPTS_FILE = "$XDG_CONFIG_HOME/fzf/fzf";

      LESSHISTFILE = "-";
      XCURSOR_PATH = "$XDG_DATA_HOME/icons";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$XDG_DATA_HOME/cargo/bin"
      "$XDG_DATA_HOME/go/bin"
      "$XDG_DATA_HOME/odin"
    ];
  };

  xdg = {
    enable = true;
    cacheHome = "$HOME/.cache";
    configHome = "$HOME/.config";
    dataHome = "$HOME/.local/share";
    stateHome = "$HOME/.local/state";
  };
}

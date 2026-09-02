{ config, ... }:

let
  liveConfig = path:
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/${path}";
in
{
  home.file.".config/lazygit/config.yml" = {
    source = liveConfig "lazygit/config.yml";
    force = true;
  };

  home.file.".config/mango/config.conf" = {
    source = liveConfig "mango/config.conf";
    force = true;
  };

  home.file.".config/wezterm/wezterm.lua" = {
    source = liveConfig "wezterm/wezterm.lua";
    force = true;
  };

  home.file.".config/television/config.toml" = {
    source = liveConfig "television/config.toml";
    force = true;
  };

  home.file.".config/television/cable" = {
    source = liveConfig "television/cable";
    force = true;
  };

  home.file.".config/tmux/tmux.conf" = {
    source = liveConfig "tmux/tmux.conf";
    force = true;
  };

  home.file.".config/yazi" = {
    source = liveConfig "yazi";
    force = true;
  };

  home.file.".config/nvim" = {
    source = liveConfig "nvim";
    force = true;
  };

  home.file.".config/fzf/fzf" = {
    source = liveConfig "fzf/fzf";
    force = true;
  };

  home.file.".config/zsh/.zshenv" = {
    source = liveConfig "zsh/.zshenv";
    force = true;
  };

  home.file.".config/zsh/.zshrc" = {
    source = liveConfig "zsh/.zshrc";
    force = true;
  };

  # Live config example:
  # home.file.".config/example/config.toml" = {
  #   source = liveConfig "example/config.toml";
  #   force = true;
  # };
  #
  # Store-managed config example:
  # home.file.".config/example/config.toml".text = ''
  #   setting = "value"
  # '';
}

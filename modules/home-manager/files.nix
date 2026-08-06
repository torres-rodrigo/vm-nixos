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

  home.file.".config/fzf/fzf" = {
    source = liveConfig "fzf/fzf";
    force = true;
  };

  home.file.".zshenv" = {
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

{ config, repoPath, ... }:

let
  liveConfig = path:
    config.lib.file.mkOutOfStoreSymlink "${repoPath}/dotfiles/${path}";
in
{
  home.file.".config/lazygit/config.yml".source =
    liveConfig "lazygit/config.yml";

  home.file.".zshenv".source =
    liveConfig "zsh/.zshenv";

  home.file.".config/zsh/.zshrc".source =
    liveConfig "zsh/.zshrc";

  # Live config example:
  # home.file.".config/example/config.toml".source =
  #   liveConfig "example/config.toml";
  #
  # Store-managed config example:
  # home.file.".config/example/config.toml".text = ''
  #   setting = "value"
  # '';
}

{ config, ... }:

let
  liveConfig = path:
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/${path}";
in
{
  home.file.".config/git/config" = {
    source = liveConfig "git/config";
    force = true;
  };

  home.file.".config/git/ignore" = {
    source = liveConfig "git/ignore";
    force = true;
  };

  home.file.".config/lazygit/config.yml" = {
    source = liveConfig "lazygit/config.yml";
    force = true;
  };

  home.file.".config/mango/config.conf" = {
    source = liveConfig "mango/config.conf";
    force = true;
  };

  home.file.".config/mango/scripts/screenshot/screenshot.sh" = {
    source = liveConfig "mango/scripts/screenshot/screenshot.sh";
    force = true;
  };

  home.file.".config/mango/scripts/capture/ocr.sh" = {
    source = liveConfig "mango/scripts/capture/ocr.sh";
    force = true;
  };

  home.file.".config/foot/foot.ini" = {
    source = liveConfig "foot/foot.ini";
    force = true;
  };

  home.file.".config/ghostty/config.ghostty" = {
    source = liveConfig "ghostty/config.ghostty";
    force = true;
  };

  home.file.".config/ghostty/tmux-tabs.css" = {
    source = liveConfig "ghostty/tmux-tabs.css";
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

  home.file.".config/tmux/foot-tmux.sh" = {
    source = liveConfig "tmux/foot-tmux.sh";
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

  home.file.".config/starship/starship.toml" = {
    source = liveConfig "starship/starship.toml";
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

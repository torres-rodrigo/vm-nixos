{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    age # Modern file encryption tool
    bat # cat replacement
    btop # resources
    chafa # Terminal graphics previews
    curl # HTTP/HTTPS/FTP transfer tool
    delta # Enhanced diff viewer
    eza # ls replacement
    exiftool # Media metadata inspection
    fd # find replacement
    fzf # Fuzzy finder
    git # Version control
    gnupg # OpenPGP encryption and signing tools
    htop # resources
    jq # JSON processor and pretty-printer
    lazygit # TUI for Git
    less # Pager
    mediainfo # Media file metadata inspection
    neovim # Text editor
    openssh # SSH client
    ripgrep # grep replacement
    starship # Shell prompt
    television # Fuzzy finder and picker
    unzip # ZIP archive extraction
    wezterm # GPU-accelerated terminal emulator
    wget # File downloader
    yazi # Terminal file manager
    zoxide # Directory jumper used by Yazi
    zsh-autosuggestions # Fish-like autosuggestions for zsh
    zsh-completions # Extra completion definitions for zsh
    zsh-syntax-highlighting # Syntax highlighting for zsh
  ];
}

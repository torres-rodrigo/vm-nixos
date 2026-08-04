{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    age # Modern file encryption tool
    bat # cat replacement
    curl # HTTP/HTTPS/FTP transfer tool
    delta # Enhanced diff viewer
    eza # ls replacement
    fd # find replacement
    git # Version control
    gnupg # OpenPGP encryption and signing tools
    jq # JSON processor and pretty-printer
    lazygit # TUI for Git
    less # Pager
    neovim # Text editor
    openssh # SSH client
    ripgrep # grep replacement
    skim # Fuzzy finder
    starship # Shell prompt
    unzip # ZIP archive extraction
    wget # File downloader
  ];
}

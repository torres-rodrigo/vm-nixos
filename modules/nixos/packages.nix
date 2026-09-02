{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    age # Modern file encryption tool
    bash-language-server # Bash language server
    bat # cat replacement
    brightnessctl # Backlight control for laptop brightness keybindings
    btop # resources
    chafa # Terminal graphics previews
    clang-tools # C/C++ language tooling
    curl # HTTP/HTTPS/FTP transfer tool
    delta # Enhanced diff viewer
    eza # ls replacement
    exiftool # Media metadata inspection
    fd # find replacement
    fzf # Fuzzy finder
    gcc # Native compiler for editor tooling
    git # Version control
    gnupg # OpenPGP encryption and signing tools
    gopls # Go language server
    htop # resources
    jq # JSON processor and pretty-printer
    lazygit # TUI for Git
    less # Pager
    lua-language-server # Lua language server
    mediainfo # Media file metadata inspection
    neovim # Text editor
    ols # Odin language server
    openssh # SSH client
    ripgrep # grep replacement
    starship # Shell prompt
    taplo # TOML language server and formatter
    television # Fuzzy finder and picker
    tree-sitter # Parser CLI used by Neovim
    unzip # ZIP archive extraction
    vscode-langservers-extracted # JSON/CSS/HTML/ESLint language servers
    wezterm # GPU-accelerated terminal emulator
    wget # File downloader
    yazi # Terminal file manager
    yaml-language-server # YAML language server
    zoxide # Directory jumper used by Yazi
    zsh-autosuggestions # Fish-like autosuggestions for zsh
    zsh-completions # Extra completion definitions for zsh
    zsh-syntax-highlighting # Syntax highlighting for zsh
  ];
}

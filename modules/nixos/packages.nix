{ lib, pkgs, ... }:

{
  programs.nano.enable = false;

  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    nixos.enable = false;
  };

  environment.extraOutputsToInstall = lib.mkForce [ ];

  environment.systemPackages = with pkgs; [
    age # Modern file encryption tool
    bash-language-server # Bash language server
    bat # cat replacement
    brightnessctl # Backlight control for laptop brightness keybindings
    btop # resources
    chafa # Terminal graphics previews
    clang # C/C++ compiler toolchain
    clang-tools # C/C++ language tooling
    curl # HTTP/HTTPS/FTP transfer tool
    deadnix # Detect unused Nix code
    delta # Enhanced diff viewer
    eza # ls replacement
    exiftool # Media metadata inspection
    fastfetch # System info temporary
    fd # find replacement
    foot # Terminal foo terminal
    fzf # Fuzzy finder
    gcc # Native compiler for editor tooling
    ghostty # Terminal
    git # Version control
    gnupg # OpenPGP encryption and signing tools
    go # Go compiler toolchain
    gopls # Go language server
    htop # resources
    jq # JSON processor and pretty-printer
    lazygit # TUI for Git
    less # Pager
    lua-language-server # Lua language server
    mediainfo # Media file metadata inspection
    neovim # Text editor
    nixd # Nix language server
    nixfmt # Official Nix formatter
    odin # Odin compiler toolchain
    ols # Odin language server
    openssh # SSH client
    ripgrep # grep replacement
    starship # Shell prompt
    statix # Nix linter
    taplo # TOML language server and formatter
    television # Fuzzy finder and picker
    tmux # Terminal multiplexer
    tree-sitter # Parser CLI used by Neovim
    unzip # ZIP archive extraction
    vscode-langservers-extracted # JSON/CSS/HTML/ESLint language servers
    wget # File downloader
    yazi # Terminal file manager
    yaml-language-server # YAML language server
    zed-editor # Text editor
    zoxide # Directory jumper used by Yazi
    zsh-autosuggestions # Fish-like autosuggestions for zsh
    zsh-completions # Extra completion definitions for zsh
    zsh-syntax-highlighting # Syntax highlighting for zsh
  ];
}

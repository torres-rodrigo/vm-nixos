environment.systemPackages = with pkgs; [
    neovim
    git
    lazygit
    ripgrep
    fastfetch

    openssh
    gh
    wl-clipboard
    xclip
  ];

  Then add this near the existing commented SSH/GPG section:

  programs.ssh.startAgent = true;


sudo nixos-rebuild switch

ssh-keygen -t ed25519 -C "your-email@example.com"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

cat ~/.ssh/id_ed25519.pub
Add to gh


ssh -T git@github.com


Set your Git author info:

  git config --global user.name "Your Name"
  git config --global user.email "your-email@example.com"


git remote -v

  Change it to SSH:

  git remote set-url origin git@github.com:OWNER/REPO.git


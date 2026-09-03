{ pkgs, ... }:

{
  xdg.configFile."zsh/nix-autosuggestions.zsh".text = ''
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  '';

  xdg.configFile."zsh/nix-syntax-highlighting.zsh".text = ''
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';
}

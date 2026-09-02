How to install it permanently without changing your configIf you want to install it permanently without 
touching your /etc/nixos/configuration.nix file, you must use nix profile add:
nix profile add nixpkgs#codex

How to uninstall itIf you used nix profile add:Find the exact element number or name assigned to it by running:
nix profile list

nix profile remove 0

nix-store --gc

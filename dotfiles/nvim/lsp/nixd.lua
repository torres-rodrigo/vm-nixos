---@type vim.lsp.Config
return {
    cmd = { 'nixd' },
    filetypes = { 'nix' },
    root_markers = { 'flake.nix', 'flake.lock', '.git' },
    settings = {
        nixd = {
            formatting = {
                command = { 'nixfmt' },
            },
            nixpkgs = {
                expr = 'import (builtins.getFlake "/etc/nixos").inputs.nixpkgs { system = "x86_64-linux"; }',
            },
            options = {
                nixos = {
                    expr = '(builtins.getFlake "/etc/nixos").nixosConfigurations.conquest.options',
                },
            },
        },
    },
}

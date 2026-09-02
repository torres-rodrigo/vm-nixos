require('config.pack').add({
    {
        src = 'neovim/nvim-lspconfig',
        setup = false,
    },
})

require('config.lsp')

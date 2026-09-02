vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup('user_gitsigns', { clear = true }),
    once = true,
    callback = function()
        require('config.pack').add({
            {
                src = 'lewis6991/gitsigns.nvim',
                setup = false,
            },
        })

        local setup_gitsigns_keymaps = require('config.keymaps').setup_gitsigns

        require('gitsigns').setup({
            current_line_blame = false,
            on_attach = function(bufnr)
                setup_gitsigns_keymaps(bufnr)
            end,
        })
    end,
})

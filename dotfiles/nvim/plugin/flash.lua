vim.api.nvim_create_autocmd('UIEnter', {
    group = vim.api.nvim_create_augroup('user_flash', { clear = true }),
    once = true,
    callback = function()
        require('config.pack').add({
            {
                src = 'folke/flash.nvim',
                setup = false,
            },
        })

        local flash = require('flash')
        local flash_keymaps = require('config.keymaps').flash
        local keymap_set = vim.keymap.set

        flash.setup(flash_keymaps)

        local flash_jump = flash.jump
        local flash_treesitter = flash.treesitter
        local flash_remote = flash.remote
        local flash_treesitter_search = flash.treesitter_search
        local flash_toggle = flash.toggle

        keymap_set({ 'n', 'x', 'o' }, 'ss', flash_jump, { desc = 'Flash' })
        keymap_set({ 'n', 'x', 'o' }, 'S', flash_treesitter, { desc = 'Flash Treesitter' })
        keymap_set('o', 'r', flash_remote, { desc = 'Remote Flash' })
        keymap_set({ 'o', 'x' }, 'R', flash_treesitter_search, { desc = 'Treesitter Search' })
        keymap_set('c', '<C-s>', flash_toggle, { desc = 'Toggle Flash Search' })
    end,
})

local set_hl = vim.api.nvim_set_hl
local scope_highlight = { link = 'DiagnosticInfo' }

local function set_highlights()
    set_hl(0, 'IblScope', scope_highlight)
end

set_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('user_ibl_highlights', { clear = true }),
    desc = 'Restore indent scope highlight',
    callback = set_highlights,
})

require('config.pack').add_on_event('UIEnter', {
    {
        src = 'lukas-reineke/indent-blankline.nvim',
        module = 'ibl',
        opts = {
            indent = {
                char = '│',
                tab_char = '│',
            },
            scope = {
                enabled = true,
                char = '│',
                highlight = 'IblScope',
                show_start = false,
                show_end = false,
            },
        },
    },
})

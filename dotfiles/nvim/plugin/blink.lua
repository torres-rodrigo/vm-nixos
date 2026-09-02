require('config.pack').add({
    {
        src = 'saghen/blink.cmp',
        version = vim.version.range('1'),
        setup = false,
    },
})

local blink = require('blink.cmp')
local keymaps = require('config.keymaps')
local lsp_config = vim.lsp.config

blink.setup({
    keymap = keymaps.blink_cmp,
    cmdline = { enabled = false },
    completion = {
        list = {
            selection = {
                preselect = true,
                auto_insert = false,
            },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 300,
        },
    },
    signature = { enabled = true },
    sources = {
        default = { 'lsp', 'path', 'buffer' },
    },
    fuzzy = {
        implementation = 'prefer_rust_with_warning',
    },
})

lsp_config('*', { capabilities = blink.get_lsp_capabilities() })

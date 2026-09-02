require('config.pack').add({
    {
        src = 'nvim-mini/mini.nvim',
        setup = false,
    },
})

local default_notify_format

require('mini.notify').setup({
    content = {
        format = function(notification)
            local data = notification.data
            if data.source == 'lsp_progress' then
                return notification.msg
            end

            default_notify_format = default_notify_format or MiniNotify.default_format
            return default_notify_format(notification)
        end,
    },
    lsp_progress = {
        enable = true,
        level = 'INFO',
        duration_last = 1000,
    },
    window = {
        config = {
            border = 'rounded',
        },
    },
})

require('mini.cmdline').setup({
    autocomplete = { enable = true },
    autocorrect = { enable = false },
    autopeek = { enable = true },
})

require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

require('mini.comment').setup()

local startup_cwd = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
startup_cwd = startup_cwd:gsub('/+$', '')
startup_cwd = startup_cwd == '' and '/' or startup_cwd
local startup_session_dir = startup_cwd == '/' and '/.sessions' or startup_cwd .. '/.sessions'
vim.g.user_project_session_dir = startup_session_dir

require('mini.sessions').setup({
    autoread = false,
    autowrite = true,
    directory = vim.fn.isdirectory(startup_session_dir) == 1 and startup_session_dir or '',
    file = '',
})

vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('user_mini_sessions_autoread', { clear = true }),
    desc = 'Autoread session only when one exists',
    nested = true,
    once = true,
    callback = function()
        if vim.fn.argc() > 0 or vim.tbl_isempty(MiniSessions.detected) then
            return
        end

        MiniSessions.read(nil, { verbose = false })
    end,
})

local keymaps = require('config.keymaps')

require('mini.ai').setup(keymaps.mini_ai)

require('mini.pairs').setup(keymaps.mini_pairs)
keymaps.setup_mini_pairs_undo_breaks()

require('mini.files').setup(keymaps.mini_files)

require('mini.surround').setup({ mappings = keymaps.mini_surround })

require('mini.splitjoin').setup(keymaps.mini_splitjoin)

require('mini.bracketed').setup(keymaps.mini_bracketed)

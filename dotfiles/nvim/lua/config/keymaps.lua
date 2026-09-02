local M = {}

local api = vim.api
local cmd = vim.cmd
local diagnostic = vim.diagnostic
local diagnostic_enable = diagnostic.enable
local diagnostic_is_enabled = diagnostic.is_enabled
local diagnostic_jump_fn = diagnostic.jump
local diagnostic_open_float = diagnostic.open_float
local fn = vim.fn
local keycode = vim.keycode
local keymap_set = vim.keymap.set
local lsp = vim.lsp
local inlay_hint = lsp.inlay_hint
local lsp_buf = lsp.buf
local tbl_extend = vim.tbl_extend
local trim = vim.trim
local ui_input = vim.ui.input
local pcall = pcall
local require = require

-- Generic keymap helper
-- modes: string or table of strings (e.g., 'n' or {'n', 'v'})
-- lhs: the key(s) you want to press     | left hand side
-- rhs: the action (command or function) | right hand side
-- desc: description of the mapping
-- opts: optional extra options
-- n - Normal
-- i - Insert
-- v - Visual and Select
-- x - Visual only
-- s - Select only
-- o - Operator-pending
-- c - Command-line
-- t - Terminal
-- l - Insert, Command-line, Lang-Arg
-- ! - Insert and Command-line
local function map(modes, lhs, rhs, desc, opts)
    opts = opts or {}
    opts.desc = desc
    keymap_set(modes, lhs, rhs, opts)
end

map('i', ',', ',<c-g>u', 'Undo break point on ,')
map('i', '.', '.<c-g>u', 'Undo break point on .')
map('i', ';', ';<c-g>u', 'Undo break point on ;')
map('i', '-', '-<c-g>u', 'Undo break point on -')
map('i', '_', '_<c-g>u', 'Undo break point on _')

map('i', '<C-S-h>', '<C-w>', 'Delete word backwards')
map('i', '<C-l>', '<C-o>x', 'Delete character forwards')
map('i', '<C-S-l>', '<C-o>dw', 'Delete word forwards')

local clear_search_escape = keycode('<Esc>')
local clear_search_on_escape = api.nvim_create_namespace('user_clear_search_on_escape')
vim.on_key(function(key)
    if key == clear_search_escape and vim.v.hlsearch == 1 then
        cmd.nohlsearch()
    end
end, clear_search_on_escape)

map('n', '/', 'ms/', 'Search forward and mark start')
map('n', '?', 'ms?', 'Search backward and mark start')

map('n', 'J', 'm<J`z', 'Join line below')

map('n', '<C-u>', '<C-u>zz', 'Page Up')
map('n', '<C-d>', '<C-d>zz', 'Page Down')
map({ 'n', 'v' }, '<C-ScrollWheelUp>', '3<C-y>', 'Scroll up 3 lines')
map({ 'n', 'v' }, '<C-ScrollWheelDown>', '3<C-e>', 'Scroll down 3 lines')
map('i', '<C-ScrollWheelUp>', '<C-o>3<C-y>', 'Scroll up 3 lines')
map('i', '<C-ScrollWheelDown>', '<C-o>3<C-e>', 'Scroll down 3 lines')

map('n', 'n', 'nzzzv', 'Next search')
map('n', 'N', 'Nzzzv', 'Previous search')

map({ 'n', 'v', 'x' }, '<leader>y', [["+y]], 'Yank to system clipboard')
map('n', '<leader>Y', [["+Y]], 'Yank line to system clipboard')
map('n', '<leader>bp', '<cmd>CopyRelativePath<CR>', 'Copy relative buffer path')
map('n', '<leader>bP', '<cmd>CopyFullPath<CR>', 'Copy full buffer path')
map('n', '<leader>bd', '<cmd>bd<CR>', 'Buffer delete')

local fn_bufnr = fn.bufnr
local buflisted = fn.buflisted
local cmd_buffer = cmd.buffer
local cmd_bnext = cmd.bnext

local function switch_to_last_or_next_buffer()
    local alternate = fn_bufnr('#')
    if alternate > 0 and buflisted(alternate) == 1 then
        cmd_buffer(alternate)
        return
    end

    cmd_bnext()
end

map('n', '<leader><leader>', switch_to_last_or_next_buffer, 'Switch to last or next buffer')
map('n', '<leader>Tn', '<cmd>tabnew<CR>', 'New tab')
map('n', '<leader>Tc', '<cmd>tabclose<CR>', 'Close tab')
map('n', '<leader>Tl', '<cmd>tabnext #<CR>', 'Last tab')

map('n', '<leader>o', 'o<Esc>', 'Insert line below normal mode')
map('n', '<leader>O', 'O<Esc>', 'Insert line above normal mode')

map({ 'n', 'v' }, '<leader>x', [["_d]], 'Delete to NULL')
map({ 'n', 'v' }, '<leader>c', [["_c]], 'Change to NULL')

map('n', '<C-c>', '<C-w>c', 'Close split but dont close file')

map('n', '<C-h>', '<C-w><C-h>', 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', 'Move focus to the right window')
map('n', '<C-j>', '<C-w><C-j>', 'Move focus to the lower window')
map('n', '<C-k>', '<C-w><C-k>', 'Move focus to the upper window')

map('n', '<C-S-h>', '<C-w>H', 'Move window to the left')
map('n', '<C-S-l>', '<C-w>L', 'Move window to the right')
map('n', '<C-S-j>', '<C-w>J', 'Move window to the lower')
map('n', '<C-S-k>', '<C-w>K', 'Move window to the upper')

map('n', '<C-Up>', ':resize +5<CR>', 'Increase split height')
map('n', '<C-Down>', ':resize -5<CR>', 'Decrease split height')
map('n', '<C-Right>', ':vertical resize +5<CR>', 'Increase split width')
map('n', '<C-Left>', ':vertical resize -5<CR>', 'Decrease split width')

map('n', '<A-j>', ':m .+1<CR>==', 'Move line down')
map('n', '<A-k>', ':m .-2<CR>==', 'Move line up')
map('v', 'K', ":m '<-2<CR>gv=gv", 'Move selection up')
map('v', 'J', ":m '>+1<CR>gv=gv", 'Move selection down')
map('v', '<', '<gv', 'Indent selection out')
map('v', '>', '>gv', 'Indent selection in')
map('v', '$', 'g_', 'Select till end of line leaving the new line')
map('n', 'gV', '`[v`]', 'Select last changed text')
map('x', '.', ':normal .<CR>', 'Repeat last change on selection')

map('n', '<leader>p', '"_diwP', 'Replace word with register without overriding register')
map({ 'v', 'x' }, '<leader>p', '"_dP', 'Replace selection with register without overriding register')

map ('n', '<leader>R', '<Cmd>restart<CR>', 'Restart config')

-- Terminal
map('n', '<leader>tf', function()
    require('config.terminal').toggle_float()
end, 'Toggle floating terminal')

map('n', '<leader>tm', '<cmd>Messages<CR>', 'Open messages')

map('n', '<leader>tn', '<cmd>Notifications<CR>', 'Open notification history')

map('n', '<leader>tb', function()
    require('config.terminal').toggle_bottom()
end, 'Toggle bottom terminal')

map('n', '<leader>lg', function()
    require('config.terminal').toggle_lazygit()
end, 'Toggle lazygit')

map('t', '<C-Space>', '<C-\\><C-n>', 'Terminal normal mode')

map('t', '<C-d>', function()
    return require('config.terminal').close_current_key()
end, 'Close managed terminal', { expr = true })

-- quicker.nvim
M.quicker = {
    edit = {
        enabled = true,
        autosave = 'unmodified',
    },
    keys = {
        {
            '>',
            function()
                require('quicker').expand({ before = 2, after = 2, add_to_existing = true })
            end,
            desc = 'Expand quickfix context',
        },
        {
            '<',
            function()
                require('quicker').collapse()
            end,
            desc = 'Collapse quickfix context',
        },
        {
            '<C-s>',
            function()
                cmd.write()
            end,
            desc = 'Save quickfix edits',
        },
    },
}

function M.setup_quicker(quicker)
    local qf_open_opts = {
        min_height = 10,
        max_height = 20,
        focus = true,
    }
    local loclist_open_opts = tbl_extend('force', qf_open_opts, { loclist = true })

    map('n', '<leader>tq', function()
        quicker.toggle(qf_open_opts)
    end, 'Toggle quickfix')

    map('n', '<leader>tl', function()
        quicker.toggle(loclist_open_opts)
    end, 'Toggle loclist')
end

--
--
-- Pickers Defaults
-- <A-a>: toggle select all.
-- <A-g>: jump to first item.
-- <A-G>: jump to last item.
-- F3: toggle preview wrap.
-- F4: toggle preview.
-- <C-s>: open in horizontal split
-- <C-v>: open in vertical split
-- <C-t>: open in new tab
-- <C-q>: CUSTOM: replace quickfix with all picker entries.
-- <A-l>: CUSTOM: replace loclist with all picker entries.
-- <A-/>: CUSTOM: append current entry to quickfix and keep focus in fzf.
-- <A-.>: CUSTOM: append current entry to loclist and keep focus in fzf.
-- <A-;>: CUSTOM: append all entries to quickfix and keep focus in fzf.
-- <A-'>: CUSTOM: append all entries to loclist and keep focus in fzf.
-- <A-p>: CUSTOM: toggle focus from preview/prompt.
-- Shift-Up / Shift-Down: page preview.
--
-- Buffer Pickers
-- Defaults
-- <C-s>: NOT WORKING
--
-- File Pickers
-- Defaults
-- <A-q>: send selected files to quickfix
-- <A-Q>: send selected files to loclist
-- <A-i>: toggle ignored files
-- <A-h>: toggle hidden files
-- <A-f>: toggle follow symlinks
-- <C-o>: CUSTOM: open in background and reload picker
--
-- Grep Pickers
-- Defaults
--
-- Diagnostics Pickers
-- Defaults
-- <C-x>: delete mark and reload picker
--
-- Keymaps Picker
-- Defaults
-- <A-d>: your custom jump to the keymap definition
--
-- Sessions Picker
-- <C-x>: delete session
-- <C-y>: create session
-- <C-p>: copy session path to clipboard and show hash
--
--

-- fzf-lua
function M.setup_fzf_lua(pickers)
    map('n', '<leader>ff', pickers.files_cwd, 'Fzf Files')
    map('n', '<leader>fF', pickers.files_prompt_dir, 'Fzf Files in directory')
    map('n', '<leader>Ff', pickers.files_cwd_fast, 'Fzf Files fast')
    map('n', '<leader>FF', pickers.files_prompt_dir_fast, 'Fzf Files in directory fast')
    map('n', '<leader>Hs', pickers.files_cwd_split, 'Fzf Files horizontal split')
    map('n', '<leader>vs', pickers.files_cwd_vsplit, 'Fzf Files vertical split')
    map('n', '<leader>vS', pickers.files_prompt_dir_vsplit, 'Fzf Files in directory vertical split')
    map('n', '<leader>VS', pickers.files_prompt_dir_fast_vsplit, 'Fzf Files in directory vertical split fast')
    map('n', '<leader>fa', pickers.autocmds, 'Fzf Autocmds')
    map('n', '<leader>fc', pickers.commands, 'Fzf Commands')
    map('n', '<leader>fr', pickers.recent_files_cwd, 'Fzf Recent files')
    map('n', '<leader>fR', pickers.recent_files_all, 'Fzf All recent files')
    map('n', '<leader>;', pickers.buffers, 'Fzf Buffers')
    map('n', '<leader>fs', pickers.sessions, 'Fzf Sessions')
    map('n', '<leader>fd', pickers.diagnostics_document, 'Fzf Document diagnostics')
    map('n', '<leader>fD', pickers.diagnostics_cwd, 'Fzf Cwd diagnostics')
    map('n', '<leader>fg', pickers.live_grep_curbuf, 'Fzf Buffer live grep')
    map('x', '<leader>fg', pickers.grep_visual, 'Fzf Buffer grep selection')
    map('n', '<leader>fG', pickers.live_grep_cwd, 'Fzf Cwd live grep')
    map('x', '<leader>fG', pickers.grep_visual_cwd, 'Fzf Cwd grep selection')
    map('n', '<leader>FG', pickers.live_grep_cwd_native, 'Fzf Cwd live grep fast')
    map('x', '<leader>FG', pickers.grep_visual_cwd_fast, 'Fzf Cwd grep selection fast')
    map('n', '<leader>gG', pickers.live_grep_prompt_dir, 'Fzf live grep in directory')
    map('n', '<leader>GG', pickers.live_grep_prompt_dir_fast, 'Fzf live grep in directory fast')
    map('n', '<leader>gr', pickers.lsp_references_buffer, 'Fzf Buffer LSP references')
    map('n', '<leader>gR', pickers.lsp_references, 'Fzf LSP references')
    map('n', '<leader>fh', pickers.help_tags, 'Fzf Help')
    map('n', '<leader>fk', pickers.keymaps, 'Fzf Keymaps')
    map('n', '<leader>m', pickers.marks, 'Fzf Marks')
    map('n', '<leader>r', pickers.registers, 'Fzf Registers')
    map('n', '<leader>nc', pickers.files_nvim_config, 'Fzf Neovim config files')
end

-- gitsigns.nvim
function M.setup_gitsigns(bufnr)
    local gs = require('gitsigns')
    local opts = { buffer = bufnr }

    map('n', '[h', function()
        if vim.wo.diff then
            cmd.normal({ '[c', bang = true })
        else
            gs.nav_hunk('prev')
        end
    end, 'Previous hunk', opts)

    map('n', ']h', function()
        if vim.wo.diff then
            cmd.normal({ ']c', bang = true })
        else
            gs.nav_hunk('next')
        end
    end, 'Next hunk', opts)

    map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk', opts)
    map('x', '<leader>hs', function()
        gs.stage_hunk({ fn.line('.'), fn.line('v') })
    end, 'Stage selected hunk', opts)

    map('n', '<leader>hu', gs.undo_stage_hunk, 'Unstage hunk', opts)
    map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk', opts)
    map('x', '<leader>hr', function()
        gs.reset_hunk({ fn.line('.'), fn.line('v') })
    end, 'Reset selected hunk', opts)

    map('n', '<leader>hS', gs.stage_buffer, 'Stage buffer', opts)
    map('n', '<leader>hU', gs.reset_buffer_index, 'Stage buffer', opts)
    map('n', '<leader>hR', gs.reset_buffer, 'Reset buffer', opts)
    map('n', '<leader>hp', gs.preview_hunk, 'Preview hunk', opts)
    map('n', '<leader>hP', gs.preview_hunk_inline, 'Preview hunk inline', opts)

    map('n', '<leader>hQ', function()
        gs.setqflist('all')
    end, 'Hunks Global quickfix list', opts)

    map('n', '<leader>hL', function()
        gs.setloclist('all')
    end, 'Hunks Global location list', opts)

    map('n', '<leader>hq', gs.setqflist, 'Buffer hunks quickfix list', opts)
    map('n', '<leader>hl', gs.setloclist, 'Buffer hunks location list', opts)

    map('n', '<leader>gd', function()
        gs.diffthis('HEAD')
    end, 'Git diff HEAD', opts)

    map('n', '<leader>gbd', function()
        ui_input({ prompt = 'Git revision: ' }, function(revision)
            revision = trim(revision or '')
            if revision == '' then
                return
            end

            gs.diffthis(revision)
        end)
    end, 'Git diff branch', opts)

    map('n', '<leader>gbB', '<cmd>Gitsigns blame<CR>', 'Git blame buffer', opts)
    map('n', '<leader>gB', gs.blame_line, 'Git blame line', opts)
    map('n', '<leader>gtb', gs.toggle_current_line_blame, 'Toggle git blame line', opts)
end

-- Folds
local folds = require('config.folds')

map('n', 'zM', function()
    cmd.normal({ 'zM', bang = true })
end, 'Close all folds')

map('n', 'zR', function()
    cmd.normal({ 'zR', bang = true })
end, 'Open all folds')

map('n', 'za', folds.toggle_current_scope, 'Toggle current fold scope')
map('n', 'zq', folds.close_next_enclosing_node, 'Close next enclosing fold')
map('n', 'zQ', folds.open_enclosing_node, 'Open enclosing fold')

local function cmdline_has_single_completion()
    local completion_type = fn.getcmdcompltype()
    local completion_pattern = fn.getcmdcomplpat()
    if completion_type == '' or completion_pattern == '' then
        return false
    end

    local ok, matches = pcall(fn.getcompletion, completion_pattern, completion_type, true)
    return ok and #matches == 1
end

local function cmdline_complete_or_accept()
    if fn.wildmenumode() == 1 then
        return keycode('<C-y>')
    end

    if cmdline_has_single_completion() then
        return keycode('<C-z><C-z><C-y>')
    end

    return keycode('<C-z>')
end

map('c', '<Tab>', cmdline_complete_or_accept, 'Complete or accept command-line completion', { expr = true })
map('c', '<C-n>', '<C-n>', 'Select next command-line completion')
map('c', '<C-p>', '<C-p>', 'Select previous command-line completion')

map('c', '<Esc>', function()
    return keycode(fn.wildmenumode() == 1 and '<C-e>' or '<C-c>')
end, 'Cancel command-line completion or exit command-line', { expr = true })

map('c', '/', function()
    if fn.getcmdtype():match('[/?]') and fn.getcmdline() == '' then
        return [[<C-c><Esc>/\%V]]
    end
    return '/'
end, 'Search within visual selection', { expr = true })

-- undotree
map('n', '<leader>u', function()
    cmd.packadd('nvim.undotree')
    require('undotree').open()
end, 'Toggle undo tree')

-- mini.files
map('n', '<leader>e', function()
    require('mini.files').open()
end, 'Open file explorer')

map('n', '<leader>E', function()
    local MiniFiles = require('mini.files')
    MiniFiles.open(api.nvim_buf_get_name(0), false)
    MiniFiles.reveal_cwd()
end, 'Open file explorer at current file')

M.mini_files = {
    mappings = {
        close = '<Esc>',
        go_in = 'l',
        go_in_plus = 'L',
        go_out = 'h',
        go_out_plus = 'H',
        mark_goto = "'",
        mark_set = 'm',
        reset = ',',
        reveal_cwd = '.',
        show_help = 'g?',
        synchronize = '=',
        trim_left = '<',
        trim_right = '>',
    },
    windows = {
        preview = false,
    },
}

-- mini.surround
M.mini_surround = {
    add = 'sa',
    delete = 'sd',
    find = 'sf',
    find_left = 'sF',
    highlight = 'sh',
    replace = 'sr',
    suffix_last = 'l',
    suffix_next = 'n',
}

-- mini.ai
M.mini_ai = {
    custom_textobjects = {},
    mappings = {
        around = 'a',
        inside = 'i',
        around_next = 'an',
        inside_next = 'in',
        around_last = 'al',
        inside_last = 'il',
        goto_left = 'g[',
        goto_right = 'g]',
    },
    n_lines = 375,
    search_method = 'cover_or_next',
    silent = false,
}

-- mini.splitjoin
M.mini_splitjoin = {
    mappings = {
        toggle = 'gS',
        split = '',
        join = '',
    },
}

-- mini.bracketed
M.mini_bracketed = {
    buffer = { suffix = 'b', options = {} },
    comment = { suffix = '/', options = {} },
    conflict = { suffix = 'x', options = {} },
    diagnostic = { suffix = 'd', options = {} },
    file = { suffix = 'f', options = {} },
    indent = { suffix = 'i', options = {} },
    jump = { suffix = 'j', options = {} },
    location = { suffix = 'l', options = {} },
    oldfile = { suffix = 'o', options = {} },
    quickfix = { suffix = 'q', options = {} },
    treesitter = { suffix = 't', options = {} },
    undo = { suffix = 'u', options = {} },
    window = { suffix = '', options = {} },
    yank = { suffix = 'y', options = {} },
}

-- flash.nvim
M.flash = {
    jump = {
        nohlsearch = true,
    },
    search = {
        exclude = {
            'flash_prompt',
            'qf',
            function(win)
                return not vim.api.nvim_win_get_config(win).focusable
            end,
        },
    },
    modes = {
        search = {
            enabled = false,
        },
        char = {
            enabled = true,
            keys = {
                f = '<M-f>',
                F = '<M-F>',
                t = '<M-t>',
                T = '<M-T>',
            },
        },
    },
}

-- blink.cmp
M.blink_cmp = {
    preset = 'none',
    ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<Tab>'] = { 'accept', 'snippet_forward', 'fallback' },
    ['<C-y>'] = { 'accept', 'fallback' },
    ['<C-e>'] = { 'cancel', 'fallback' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
}

-- mini.pairs
M.mini_pairs = {
    modes = {
        insert = true,
        command = false,
        terminal = false,
    },
    mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '^[^\\]' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '^[^\\]' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '^[^\\]' },
        [')'] = { action = 'close', pair = '()', neigh_pattern = '^[^\\]' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '^[^\\]' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '^[^\\]' },
        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '^[^\\]', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '^[^%a\\]', register = { cr = false } },
        ['`'] = false,
    },
}

function M.setup_mini_pairs_undo_breaks()
    local function open_with_undo_break(pair, neigh_pattern)
        return function()
            return MiniPairs.open(pair, neigh_pattern) .. vim.keycode('<C-g>u')
        end
    end

    local function closeopen_with_undo_break(pair, neigh_pattern)
        return function()
            return MiniPairs.closeopen(pair, neigh_pattern) .. vim.keycode('<C-g>u')
        end
    end

    map('i', '(', open_with_undo_break('()', '^[^\\]'), 'Open () pair with undo break', {
        expr = true,
        replace_keycodes = false,
    })

    map('i', '[', open_with_undo_break('[]', '^[^\\]'), 'Open [] pair with undo break', {
        expr = true,
        replace_keycodes = false,
    })

    map('i', '{', open_with_undo_break('{}', '^[^\\]'), 'Open {} pair with undo break', {
        expr = true,
        replace_keycodes = false,
    })

    map('i', '"', closeopen_with_undo_break('""', '^[^\\]'), 'Open or close "" pair with undo break', {
        expr = true,
        replace_keycodes = false,
    })

    map('i', "'", closeopen_with_undo_break("''", '^[^%a\\]'), "Open or close '' pair with undo break", {
        expr = true,
        replace_keycodes = false,
    })
end

-- LSP
local function set_references_quickfix(list)
    fn.setqflist({}, ' ', {
        title = list.title,
        items = list.items,
        context = list.context,
    })
    cmd('botright copen')
end

local function references_to_quickfix()
    lsp_buf.references(nil, {
        on_list = function(list)
            set_references_quickfix(list)
        end,
    })
end

local function visual_references_to_quickfix(reference_fn)
    local cursor = api.nvim_win_get_cursor(0)
    local start = api.nvim_buf_get_mark(0, '<')

    api.nvim_win_set_cursor(0, { start[1], start[2] })
    reference_fn()
    api.nvim_win_set_cursor(0, cursor)
end

function M.setup_lsp(client, bufnr, border)
    local opts = { buffer = bufnr }

    local function supports(method)
        return client:supports_method(method, bufnr)
    end

    if supports('textDocument/definition') then
        map('n', 'gd', lsp_buf.definition, 'Go to definition', opts)
    end

    if supports('textDocument/declaration') then
        map('n', 'gD', lsp_buf.declaration, 'Go to declaration', opts)
    end

    if supports('textDocument/references') then
        map('n', 'gr', references_to_quickfix, 'LSP references quickfix', opts)
        map('x', 'gr', function()
            visual_references_to_quickfix(references_to_quickfix)
        end, 'LSP selection references quickfix', opts)
    end

    if supports('textDocument/hover') then
        map('n', 'K', function()
            lsp_buf.hover(border)
        end, 'LSP hover', opts)
    end

    if supports('textDocument/signatureHelp') then
        map({ 'i', 's' }, '<C-s>', function()
            lsp_buf.signature_help(border)
        end, 'LSP signature help', opts)
    end

    if supports('textDocument/formatting') then
        map('n', '<leader>lf', function()
            lsp_buf.format({
                bufnr = bufnr,
                timeout_ms = 1000,
                filter = function(format_client)
                    return format_client.id == client.id
                end,
            })
        end, 'Format buffer', opts)
    end

    if supports('workspace/symbol') then
        map('n', '<leader>lS', lsp_buf.workspace_symbol, 'Workspace symbol', opts)
    end

    if supports('textDocument/inlayHint') then
        local inlay_hint_opts = { bufnr = bufnr }
        map('n', '<leader>ti', function()
            local enabled = inlay_hint.is_enabled(inlay_hint_opts)
            inlay_hint.enable(not enabled, inlay_hint_opts)
        end, 'Toggle inlay hints', opts)
    end
end

-- Diagnostics
local diagnostics = require('config.diagnostics')
local severity = diagnostic.severity
local diagnostic_jump = {
    prev_error = { count = -1, severity = severity.ERROR, wrap = false },
    next_error = { count = 1, severity = severity.ERROR, wrap = false },
    prev_warn = { count = -1, severity = severity.WARN, wrap = false },
    next_warn = { count = 1, severity = severity.WARN, wrap = false },
}
local line_diagnostics = { scope = 'line' }

map('n', '[e', function()
    diagnostic_jump_fn(diagnostic_jump.prev_error)
end, 'Previous error')

map('n', ']e', function()
    diagnostic_jump_fn(diagnostic_jump.next_error)
end, 'Next error')

map('n', '[w', function()
    diagnostic_jump_fn(diagnostic_jump.prev_warn)
end, 'Previous warning')

map('n', ']w', function()
    diagnostic_jump_fn(diagnostic_jump.next_warn)
end, 'Next warning')

map('n', '<leader>ld', function()
    diagnostic_open_float(line_diagnostics)
end, 'Line diagnostics')

map('n', '<leader>lld', diagnostics.open_loclist, 'Diagnostic location list')
map('n', '<leader>qld', diagnostics.open_qflist, 'Diagnostic quickfix list')

map('n', '<leader>td', function()
    diagnostic_enable(not diagnostic_is_enabled())
end, 'Toggle diagnostics')

map('n', '<leader>tvd', function()
    diagnostics.toggle_display('virtual_lines')
end, 'Toggle diagnostic virtual lines')

map('n', '<leader>tvt', function()
    diagnostics.toggle_display('virtual_text')
end, 'Toggle diagnostic virtual text')

map('n', '<leader>tsd', function()
    diagnostics.toggle_display('signs')
end, 'Toggle diagnostic signs')

map('n', '<leader>tud', function()
    diagnostics.toggle_display('underline')
end, 'Toggle diagnostic underline')

return M

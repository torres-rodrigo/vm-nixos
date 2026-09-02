local create_augroup = vim.api.nvim_create_augroup
local create_autocmd = vim.api.nvim_create_autocmd
local buf_get_mark = vim.api.nvim_buf_get_mark
local buf_line_count = vim.api.nvim_buf_line_count
local get_current_win = vim.api.nvim_get_current_win
local bo = vim.bo
local cmd = vim.cmd
local fn = vim.fn
local hl_on_yank = vim.hl.on_yank
local keymap_set = vim.keymap.set
local notify = vim.notify
local opt_local = vim.opt_local
local uv = vim.uv
local warn = vim.log.levels.WARN
local wo = vim.wo
local pcall = pcall
local str_format = string.format
local str_match = string.match

local function augroup(name)
    return create_augroup('user_' .. name, { clear = true })
end

local cursor_restore_ignored = {
    gitcommit = true,
    gitrebase = true,
    svn = true,
    hgcommit = true,
}

local comment_formatoptions = { 'c', 'r', 'o' }

local function close_quickfix_or_loclist()
    local wininfo = fn.getwininfo(get_current_win())[1]
    if wininfo and wininfo.loclist == 1 then
        cmd.lclose()
    else
        cmd.cclose()
    end
end

local function current_quickfix_entry()
    local wininfo = fn.getwininfo(get_current_win())[1]
    local list = wininfo and wininfo.loclist == 1 and fn.getloclist(0) or fn.getqflist()
    return list[fn.line('.')]
end

local function copy_quickfix_entry_path(modifier)
    local entry = current_quickfix_entry()
    if not entry then
        notify('No quickfix entry under cursor', warn)
        return
    end

    local path = entry.bufnr and entry.bufnr > 0 and fn.bufname(entry.bufnr) or entry.filename
    if not path or path == '' then
        notify('Quickfix entry has no file path', warn)
        return
    end

    path = fn.fnamemodify(path, modifier)
    fn.setreg('+', path)
    notify('Copied: ' .. path)
end

create_autocmd('TextYankPost', {
    group = augroup('highlight_yank'),
    desc = 'Highlight yanked text',
    callback = function()
        hl_on_yank()
    end,
})

create_autocmd('BufReadPost', {
    group = augroup('restore_cursor'),
    desc = 'Restore cursor to the last known position',
    callback = function(args)
        if cursor_restore_ignored[bo[args.buf].filetype] or wo.diff then
            return
        end

        local mark = buf_get_mark(args.buf, '"')
        local line_count = buf_line_count(args.buf)

        if mark[1] > 0 and mark[1] <= line_count then
            pcall(cmd.normal, { 'g`"zz', bang = true })
        end
    end,
})

create_autocmd('BufWritePre', {
    group = augroup('create_parent_dirs'),
    desc = 'Create missing parent directories before writing a file',
    callback = function(args)
        if args.match == '' or bo[args.buf].buftype ~= '' then
            return
        end

        local file = uv.fs_realpath(args.match) or args.match

        if str_match(file, '^%w%w+://') then
            return
        end

        local dir = fn.fnamemodify(file, ':p:h')

        if dir ~= '' and fn.isdirectory(dir) == 0 then
            fn.mkdir(dir, 'p')
        end
    end,
})

create_autocmd('FileType', {
    group = augroup('close_with_q'),
    desc = 'Close transient buffers with q',
    pattern = {
        'git',
        'help',
        'man',
        'scratch',
    },
    callback = function(args)
        if args.match == 'help' and bo[args.buf].modifiable then
            return
        end

        keymap_set('n', 'q', '<Cmd>quit<CR>', {
            buffer = args.buf,
            silent = true,
            desc = 'Close buffer',
        })
    end,
})

create_autocmd('FileType', {
    group = augroup('close_qf_with_Q'),
    desc = 'Close quickfix and location list buffers with Q',
    pattern = 'qf',
    callback = function(args)
        keymap_set('n', 'Q', close_quickfix_or_loclist, {
            buffer = args.buf,
            silent = true,
            desc = 'Close quickfix or location list',
        })
        keymap_set('n', '<leader>bp', function()
            copy_quickfix_entry_path(':.')
        end, {
            buffer = args.buf,
            silent = true,
            desc = 'Copy quickfix entry relative path',
        })
        keymap_set('n', '<leader>bP', function()
            copy_quickfix_entry_path(':p')
        end, {
            buffer = args.buf,
            silent = true,
            desc = 'Copy quickfix entry full path',
        })
    end,
})

create_autocmd('CmdwinEnter', {
    group = augroup('close_command_window'),
    desc = 'Close the command-line window with q',
    callback = function(args)
        keymap_set('n', 'q', '<C-W>c', {
            buffer = args.buf,
            silent = true,
            desc = 'Close command-line window',
        })
    end,
})

create_autocmd('TermOpen', {
    group = augroup('terminal_start_insert'),
    desc = 'Start terminal buffers in insert mode with minimal window UI',
    callback = function()
        opt_local.number = false
        opt_local.relativenumber = false
        opt_local.signcolumn = 'no'
        cmd.startinsert()
    end,
})

create_autocmd('FileType', {
    group = augroup('formatoptions'),
    desc = 'Do not auto-continue comments',
    callback = function()
        opt_local.formatoptions:remove(comment_formatoptions)
    end,
})

create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
    group = augroup('check_external_changes'),
    desc = 'Check whether files changed outside Neovim',
    callback = function()
        if fn.mode() ~= 'c' then
            cmd.checktime()
        end
    end,
})

create_autocmd('FileChangedShellPost', {
    group = augroup('external_change_notice'),
    desc = 'Notify when a file changed outside Neovim',
    callback = function(args)
        notify(str_format('Reloaded file changed on disk: %s', fn.fnamemodify(args.file, ':t')))
    end,
})

create_autocmd({ 'WinEnter', 'BufEnter', 'FocusGained' }, {
    group = augroup('cursorline_enable'),
    desc = 'Enable cursorline in the active window',
    callback = function()
        wo.cursorline = true
    end,
})

create_autocmd({ 'WinLeave', 'FocusLost' }, {
    group = augroup('cursorline_disable'),
    desc = 'Disable cursorline outside the active window',
    callback = function()
        wo.cursorline = false
    end,
})

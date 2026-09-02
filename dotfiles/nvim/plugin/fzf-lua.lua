require('config.pack').add({
    {
        src = 'ibhagwan/fzf-lua',
        setup = false,
    },
})

local fzf = require('fzf-lua')
local actions = require('fzf-lua.actions')
local fzf_path = require('fzf-lua.path')
local sessions = require('config.sessions')
local utils = require('fzf-lua.utils')
local win_get_buf = vim.api.nvim_win_get_buf
local win_set_buf = vim.api.nvim_win_set_buf
local win_is_valid = vim.api.nvim_win_is_valid
local set_current_win = vim.api.nvim_set_current_win
local set_current_tabpage = vim.api.nvim_set_current_tabpage
local list_tabpages = vim.api.nvim_list_tabpages
local tabpage_list_wins = vim.api.nvim_tabpage_list_wins
local get_current_buf = vim.api.nvim_get_current_buf
local create_user_command = vim.api.nvim_create_user_command
local keymap_set = vim.keymap.set
local schedule = vim.schedule
local defer_fn = vim.defer_fn
local tbl_extend = vim.tbl_extend
local tbl_deep_extend = vim.tbl_deep_extend
local tbl_isempty = vim.tbl_isempty
local getqflist = vim.fn.getqflist
local setqflist = vim.fn.setqflist
local getloclist = vim.fn.getloclist
local setloclist = vim.fn.setloclist
local cmd = vim.cmd
local buf_line_count = vim.api.nvim_buf_line_count
local win_set_cursor = vim.api.nvim_win_set_cursor
local min = math.min
local fnameescape = vim.fn.fnameescape
local fnamemodify = vim.fn.fnamemodify
local expand = vim.fn.expand
local getcwd = vim.fn.getcwd
local getreg = vim.fn.getreg
local getregtype = vim.fn.getregtype
local setreg = vim.fn.setreg
local stdpath = vim.fn.stdpath
local joinpath = vim.fs.joinpath
local fs_relpath = vim.fs.relpath
local diagnostic_get = vim.diagnostic.get
local buf_is_valid = vim.api.nvim_buf_is_valid
local buf_get_name = vim.api.nvim_buf_get_name
local trim = vim.trim
local notify = vim.notify
local warn = vim.log.levels.WARN
local fs_stat = vim.uv.fs_stat
local pcall = pcall
local ipairs = ipairs
local sort = table.sort
local assert = assert
local format = string.format
local max = math.max
local fzf_win

local function current_fzf_win()
    if not fzf_win then
        local ok, win = pcall(require, 'fzf-lua.win')
        if not ok then
            return nil
        end
        fzf_win = win
    end

    return fzf_win.__SELF()
end

local function focus_fzf_prompt()
    local current = current_fzf_win()
    local fzf_winid = current and current.fzf_winid

    if fzf_winid and win_is_valid(fzf_winid) then
        set_current_win(fzf_winid)
        cmd.startinsert()
    end
end

local function map_preview_focus_toggle()
    local current = current_fzf_win()
    local preview_winid = current and current.preview_winid

    if not preview_winid or not win_is_valid(preview_winid) then
        return
    end

    local bufnr = win_get_buf(preview_winid)
    local buffer_vars = vim.b[bufnr]
    if buffer_vars.user_fzf_preview_focus_toggle then
        return
    end

    buffer_vars.user_fzf_preview_focus_toggle = true
    keymap_set('n', '<A-p>', focus_fzf_prompt, {
        buffer = bufnr,
        desc = 'Focus fzf prompt',
        nowait = true,
    })
end

local function setup_preview_focus_toggle()
    vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
        group = vim.api.nvim_create_augroup('user_fzf_lua_preview_focus', { clear = true }),
        desc = 'Map fzf preview focus toggle',
        callback = map_preview_focus_toggle,
    })

    schedule(map_preview_focus_toggle)
end

local function jump_to_keymap_definition(selected)
    if not selected[1] then
        return
    end

    local entry = fzf_path.keymap_to_entry(selected[1])
    if not entry.path then
        notify('Could not find keymap definition', warn)
        return
    end

    cmd.edit(fnameescape(entry.path))

    if entry.line and entry.line > 0 then
        local line_count = buf_line_count(0)
        win_set_cursor(0, { min(entry.line, line_count), 0 })
        cmd.normal({ 'zz', bang = true })
    end
end

local global_config = {
    fzf_opts = {
        ['--cycle'] = true,
    },
    keymap = {
        builtin = {
            true,
            ['<A-p>'] = 'focus-preview',
        },
    },
    winopts = {
        title_flags = false,
        on_create = setup_preview_focus_toggle,
    },
}

local function selected_to_qf_items(selected, opts)
    local qf_items = {}

    for _, item in ipairs(selected) do
        local file = fzf_path.entry_to_file(item, opts)
        local text = assert(file.stripped):match(':%d+:%d?%d?%d?%d?:?(.*)$')
        qf_items[#qf_items + 1] = {
            bufnr = file.bufnr,
            filename = file.bufname or file.path or file.uri,
            lnum = file.line or 0,
            valid = 1,
            col = file.col,
            text = text,
        }
    end

    sort(qf_items, function(a, b)
        if a.filename ~= b.filename then
            return a.filename < b.filename
        end
        if a.lnum ~= b.lnum then
            return a.lnum < b.lnum
        end
        return (a.col or 0) < (b.col or 0)
    end)

    return qf_items
end

local function list_title(opts)
    local fzf_cmd = utils.get_info().cmd
    local ok, query = pcall(utils.resume_get, 'query', opts)
    return format('[FzfLua] %s%s', fzf_cmd and fzf_cmd .. ': ' or '', ok and query or '')
end

local function replace_qf(selected, opts)
    setqflist({}, ' ', {
        title = list_title(opts),
        items = selected_to_qf_items(selected, opts),
    })
    cmd(opts.copen or 'botright copen')
end

local function replace_ll(selected, opts)
    setloclist(0, {}, ' ', {
        title = list_title(opts),
        items = selected_to_qf_items(selected, opts),
    })
    cmd(opts.lopen or 'botright lopen')
end

local function append_to_qf(selected, opts)
    local qflist = getqflist({ size = 0, title = 0 })
    local data = { items = selected_to_qf_items(selected, opts) }
    if qflist.size == 0 and qflist.title == '' then
        data.title = list_title(opts)
    end

    setqflist({}, 'a', data)
    cmd(opts.copen or 'botright copen')
end

local function append_to_ll(selected, opts)
    local loclist = getloclist(0, { size = 0, title = 0 })
    local data = { items = selected_to_qf_items(selected, opts) }
    if loclist.size == 0 and loclist.title == '' then
        data.title = list_title(opts)
    end

    setloclist(0, {}, 'a', data)
    cmd(opts.lopen or 'botright lopen')
end

local function append_to_qf_and_focus(selected, opts)
    append_to_qf(selected, opts)
    schedule(focus_fzf_prompt)
end

local function append_to_ll_and_focus(selected, opts)
    append_to_ll(selected, opts)
    schedule(focus_fzf_prompt)
end

local function list_export_actions()
    return {
        ['ctrl-q'] = { fn = replace_qf, prefix = 'select-all+' },
        ['alt-l'] = { fn = replace_ll, prefix = 'select-all+' },
        ['alt-/'] = {
            fn = append_to_qf_and_focus,
            exec_silent = true,
            field_index = '{}',
            postfix = 'unbind(alt-/)+rebind(alt-/)',
        },
        ['alt-.'] = {
            fn = append_to_ll_and_focus,
            exec_silent = true,
            field_index = '{}',
            postfix = 'unbind(alt-.)+rebind(alt-.)',
        },
        ['alt-;'] = {
            fn = append_to_qf_and_focus,
            prefix = 'select-all+',
            exec_silent = true,
            field_index = '{+}',
            postfix = 'unbind(alt-;)+rebind(alt-;)',
        },
        ["alt-'"] = {
            fn = append_to_ll_and_focus,
            prefix = 'select-all+',
            exec_silent = true,
            field_index = '{+}',
            postfix = "unbind(alt-')+rebind(alt-')",
        },
    }
end

local function with_list_export_actions(picker_actions)
    return tbl_extend('force', list_export_actions(), picker_actions or {})
end

local file_config = {
    fd_opts = '--color=never --hidden --follow --exclude .git --no-ignore --type f --type l',
    actions = with_list_export_actions({
        ['enter'] = actions.file_edit,
        ['ctrl-o'] = { fn = actions.file_open_in_background, reload = true },
    }),
}

local function file_config_with_enter(action)
    return tbl_deep_extend('force', file_config, {
        actions = with_list_export_actions({
            ['enter'] = action,
            ['ctrl-o'] = { fn = actions.file_open_in_background, reload = true },
        }),
    })
end

local file_split_config = file_config_with_enter(actions.file_split)
local file_vsplit_config = file_config_with_enter(actions.file_vsplit)

local function switch_to_visible_buffer_or_edit(selected, opts)
    local item = selected[1]
    if not item then
        return
    end

    local entry = fzf_path.entry_to_file(item, opts)
    local bufnr = entry and entry.bufnr
    if not bufnr then
        actions.buf_switch_or_edit(selected, opts)
        return
    end

    for _, tabpage in ipairs(list_tabpages()) do
        for _, winid in ipairs(tabpage_list_wins(tabpage)) do
            if win_get_buf(winid) == bufnr then
                set_current_tabpage(tabpage)
                set_current_win(winid)

                if entry.line and entry.line > 0 or entry.col and entry.col > 0 then
                    pcall(win_set_cursor, 0, { max(1, entry.line or 1), max(1, (entry.col or 1)) - 1 })
                end

                return
            end
        end
    end

    actions.buf_switch_or_edit(selected, opts)
end

local buffer_config = {
    previewer = 'builtin',
    sort_lastused = true,
    actions = with_list_export_actions({
        ['enter'] = switch_to_visible_buffer_or_edit,
    }),
}

local function grep_config(opts)
    return tbl_deep_extend('force', {
        actions = with_list_export_actions({
            ['ctrl-g'] = { actions.grep_lgrep },
        }),
    }, opts or {})
end

local function buffer_picker_config(opts)
    return tbl_deep_extend('force', {
        buffers = opts and opts.buffers or buffer_config,
        config = {
            winopts = {
                preview = {
                    hidden = false,
                    default = 'builtin',
                },
                title = ' Buffers '
            },
        },
    }, opts or {})
end

local function fast_grep_config(opts)
    return grep_config(tbl_deep_extend('force', {
        multiprocess = 1,
        git_icons = false,
        file_icons = false,
        file_ignore_patterns = false,
        strip_cwd_prefix = false,
        render_crlf = false,
        path_shorten = false,
        formatter = false,
        multiline = false,
        rg_glob = false,
    }, opts or {}))
end

local fast_file_config = tbl_deep_extend('force', file_config, {
    previewer = 'builtin',
    multiprocess = true,
    git_icons = false,
    file_icons = false,
    color_icons = false,
    fzf_opts = {
        ['--ansi'] = false,
        ['--multi'] = true,
        ['--scheme'] = 'path',
    },
})

local fast_file_vsplit_config = tbl_deep_extend('force', fast_file_config, {
    actions = file_vsplit_config.actions,
})

local fast_config = {
    winopts = {
        preview = {
            default = 'builtin',
        },
    },
}

local function setup_profile(profile, opts)
    opts = opts or {}
    fzf.setup(tbl_deep_extend('force', {
        profile,
        files = opts.files or file_config,
        buffers = opts.buffers,
    }, global_config, opts.config or {}))
end

setup_profile('default-title')

local function normalize_dir(input, cwd)
    local dir = trim(utils.strip_ansi_coloring(input or ''))
    if dir == '' then
        return nil
    end

    local first = dir:sub(1, 1)
    if first == '~' or first == '/' then
        return fnamemodify(expand(dir), ':p')
    end

    return fnamemodify(joinpath(cwd or getcwd(), dir), ':p')
end

local function open_files_in_dir(dir, opts)
    opts = opts or {}
    setup_profile(opts.profile or 'default-title', {
        files = opts.files,
        config = opts.config,
    })
    fzf.files({ cwd = dir })
end

local function open_fast_files_in_dir(dir)
    open_files_in_dir(dir, {
        profile = 'max-perf',
        files = fast_file_config,
        config = fast_config,
    })
end

local function open_split_files_in_dir(dir)
    open_files_in_dir(dir, {
        files = file_split_config,
    })
end

local function open_vsplit_files_in_dir(dir)
    open_files_in_dir(dir, {
        files = file_vsplit_config,
    })
end

local function open_fast_vsplit_files_in_dir(dir)
    open_files_in_dir(dir, {
        profile = 'max-perf',
        files = fast_file_vsplit_config,
        config = fast_config,
    })
end

local function open_grep_in_dir(dir, opts)
    opts = opts or {}
    setup_profile(opts.profile or 'default-title', {
        config = opts.config,
    })
    opts.open_grep(grep_config({
        cwd = dir,
    }))
end

local function open_live_grep_in_dir(dir)
    open_grep_in_dir(dir, {
        open_grep = fzf.live_grep,
    })
end

local function open_fast_live_grep_in_dir(dir)
    setup_profile('max-perf', {
        config = fast_config,
    })
    fzf.live_grep_native(fast_grep_config({
        cwd = dir,
    }))
end

local function path_in_dir(path, dir)
    path = fnamemodify(path, ':p')
    dir = fnamemodify(dir, ':p')

    local ok, relpath = pcall(fs_relpath, dir, path)
    return ok and relpath and relpath ~= '' and not relpath:match('^%.%.[/]?')
end

local function has_cwd_diagnostics(cwd)
    for _, diagnostic in ipairs(diagnostic_get(nil)) do
        if buf_is_valid(diagnostic.bufnr) then
            local path = buf_get_name(diagnostic.bufnr)
            if path ~= '' and path_in_dir(path, cwd) then
                return true
            end
        end
    end

    return false
end

local function diagnostics_picker_opts(opts)
    return tbl_deep_extend('force', {
        previewer = false,
        winopts = {
            border = { '', '─', '', '', '', '', '', '' },
            row = 1,
            height = 0.40,
            title = ' Diagnostics ',
            title_pos = 'center',
        },
    }, opts or {})
end

local function open_empty_diagnostics(title)
    setup_profile('ivy')
    fzf.fzf_exec({}, diagnostics_picker_opts({
        prompt = 'Diagnostics> ',
        winopts = {
            title = (' %s '):format(title),
            title_pos = 'center',
        },
    }))
end

local function ivy_winopts(title, opts)
    return tbl_deep_extend('force', {
        border = { '', '─', '', '', '', '', '', '' },
        height = 0.40,
        preview = {
            horizontal = 'right:50%',
            layout = 'horizontal',
            border = { '', '─', '', '', '', '', '', '' },
        },
        title = title,
        title_pos = 'center',
    }, opts or {})
end

local pickers = {}

function pickers.files_cwd()
    open_files_in_dir(getcwd())
end

function pickers.files_cwd_split()
    open_split_files_in_dir(getcwd())
end

function pickers.files_cwd_vsplit()
    open_vsplit_files_in_dir(getcwd())
end

function pickers.files_nvim_config()
    open_files_in_dir(stdpath('config'))
end

function pickers.files_cwd_fast()
    open_fast_files_in_dir(getcwd())
end

function pickers.recent_files_cwd()
    setup_profile('default-title')
    fzf.history({
        cwd_only = true,
        actions = file_config.actions,
    })
end

function pickers.recent_files_all()
    setup_profile('default-title')
    fzf.history({
        actions = file_config.actions,
    })
end

function pickers.buffers()
    setup_profile('fzf-vim', buffer_picker_config())
    fzf.buffers()
end

function pickers.sessions()
    local session_by_display = {}

    local function session_entries(fzf_cb)
        session_by_display = {}

        for _, session in ipairs(sessions.project_sessions_for_picker()) do
            session_by_display[session.display] = session.internal
            fzf_cb(session.display)
        end

        fzf_cb()
    end

    setup_profile('fzf-vim', {
        config = {
            winopts = {
                preview = {
                    hidden = true,
                },
                title = ' Sessions ',
            },
        },
    })
    fzf.fzf_exec(session_entries, {
        prompt = format('Session:%s> ', sessions.current_display_name() or ''),
        actions = {
            ['enter'] = function(selected)
                local display = selected[1]
                if not display then
                    return
                end

                local internal = session_by_display[display]
                if internal then
                    defer_fn(function()
                        sessions.read_internal(internal)
                    end, 25)
                end
            end,
            ['ctrl-x'] = {
                fn = function(selected)
                    local display = selected[1]
                    if not display then
                        return
                    end

                    local internal = session_by_display[display]
                    if internal then
                        sessions.delete_internal(internal)
                    end
                end,
                desc = 'session-delete',
                reload = true,
            },
            ['ctrl-y'] = {
                fn = function(_, picker_opts)
                    local name = trim(picker_opts.last_query or '')
                    sessions.create(name)
                end,
                desc = 'session-create',
            },
            ['ctrl-p'] = {
                fn = function()
                    sessions.show_directory()
                end,
                desc = 'session-directory',
                exec_silent = true,
            },
        },
    })
end

local function selected_to_buffers(selected, opts, source_bufnr)
    local buffers = {}
    local seen = {
        [source_bufnr] = true,
    }

    for _, item in ipairs(selected) do
        local file = fzf_path.entry_to_file(item, opts)
        local bufnr = file and file.bufnr

        if bufnr and buf_is_valid(bufnr) and not seen[bufnr] then
            seen[bufnr] = true
            buffers[#buffers + 1] = bufnr
        end
    end

    return buffers
end

local function diff_selected_buffers(selected, opts, source_bufnr)
    local buffers = selected_to_buffers(selected, opts, source_bufnr)
    if #buffers == 0 then
        notify('No buffers selected for diff', warn)
        return
    end

    schedule(function()
        if not buf_is_valid(source_bufnr) then
            notify('Original buffer is no longer available', warn)
            return
        end

        cmd.tabnew()
        win_set_buf(0, source_bufnr)
        cmd.diffthis()

        for _, bufnr in ipairs(buffers) do
            cmd.vsplit()
            win_set_buf(0, bufnr)
            cmd.diffthis()
        end
    end)
end

function pickers.diff_buffers()
    local source_bufnr = get_current_buf()

    setup_profile('fzf-vim', buffer_picker_config({
        buffers = tbl_deep_extend('force', buffer_config, {
            actions = with_list_export_actions({
                ['enter'] = function(selected, opts)
                    diff_selected_buffers(selected, opts, source_bufnr)
                end,
            }),
        }),
    }))
    fzf.buffers({
        fzf_opts = {
            ['--multi'] = true,
        },
    })
end

function pickers.live_grep_curbuf()
    setup_profile('default-title')
    fzf.lgrep_curbuf(grep_config())
end

function pickers.live_grep_cwd()
    setup_profile('default-title')
    fzf.live_grep(grep_config({
        cwd = getcwd(),
    }))
end

function pickers.live_grep_cwd_native()
    setup_profile('default-title')
    fzf.live_grep_native(grep_config({
        cwd = getcwd(),
    }))
end

function pickers.grep_visual()
    setup_profile('default-title')
    fzf.grep_curbuf(grep_config({
        search = utils.get_visual_selection(),
    }))
end

function pickers.grep_visual_cwd()
    setup_profile('default-title')
    fzf.grep_visual(grep_config({
        cwd = getcwd(),
    }))
end

function pickers.grep_visual_cwd_fast()
    setup_profile('default-title')
    fzf.grep_visual(fast_grep_config({
        cwd = getcwd(),
    }))
end

function pickers.diagnostics_document()
    if tbl_isempty(diagnostic_get(0)) then
        open_empty_diagnostics('Diagnostics')
        return
    end

    setup_profile('ivy')
    fzf.diagnostics_document(diagnostics_picker_opts({
        actions = list_export_actions(),
    }))
end

function pickers.diagnostics_cwd()
    local cwd = getcwd()
    if not has_cwd_diagnostics(cwd) then
        open_empty_diagnostics('Diagnostics')
        return
    end

    setup_profile('ivy')
    fzf.diagnostics_workspace(diagnostics_picker_opts({
        actions = list_export_actions(),
        cwd = cwd,
    }))
end

function pickers.lsp_references_buffer()
    setup_profile('ivy')
    fzf.lsp_references({
        current_buffer_only = true,
        winopts = ivy_winopts(' References '),
    })
end

function pickers.lsp_references()
    setup_profile('ivy')
    fzf.lsp_references({
        winopts = ivy_winopts(' All References '),
    })
end

function pickers.help_tags()
    setup_profile('ivy')
    fzf.help_tags({
        winopts = ivy_winopts(' Neovim Help '),
    })
end

function pickers.marks()
    setup_profile('ivy')
    fzf.marks({
        actions = list_export_actions(),
        sort = false,
        winopts = ivy_winopts(' Marks '),
    })
end

local function copy_register_to_clipboard(selected)
    local item = selected[1]
    if not item then
        return
    end

    local register = item:match('%[(.-)%]')
    if not register then
        return
    end

    local contents = getreg(register)
    if contents == '' then
        return
    end

    setreg('+', contents, getregtype(register))
    notify(('Copied register %s to clipboard'):format(register))
end

function pickers.registers()
    setup_profile('ivy')
    fzf.registers({
        multiline = 1,
        filter = '^["0-9a-zA-Z*+]$',
        actions = {
            ['enter'] = actions.paste_register,
            ['ctrl-y'] = copy_register_to_clipboard,
        },
        winopts = ivy_winopts(' Registers '),
    })
end

function pickers.autocmds()
    setup_profile('ivy')
    fzf.autocmds({
        winopts = ivy_winopts(' Autocmds '),
    })
end

function pickers.commands()
    setup_profile('ivy')
    fzf.commands({
        winopts = ivy_winopts(' Commands '),
    })
end

function pickers.keymaps()
    setup_profile('ivy')
    fzf.keymaps({
        previewer = false,
        actions = {
            ['alt-d'] = jump_to_keymap_definition,
        },
        winopts = ivy_winopts(' Keymaps ', {
            width = 0.55,
            col = 0.99,
        }),
    })
end

local function pick_files_from_prompted_dir(opts)
    local cwd = expand('~')

    setup_profile(opts.profile or 'fzf-vim', {
        files = opts.files,
        config = opts.config,
    })
    fzf.fzf_exec('fd --hidden --follow --exclude .git --no-ignore --type d', {
        cwd = cwd,
        prompt = 'Directories> ',
        fzf_opts = tbl_deep_extend('force', {
            ['--print-query'] = true,
        }, opts.fzf_opts or {}),
        actions = {
            ['enter'] = function(selected, picker_opts)
                local query = trim(picker_opts.last_query or '')
                local dir = query == '' and cwd or selected[1] and normalize_dir(selected[1], picker_opts.cwd)
                if not dir then
                    return
                end

                local stat = fs_stat(dir)
                if not stat or stat.type ~= 'directory' then
                    notify(('Not a directory: %s'):format(dir), warn)
                    return
                end

                schedule(function()
                    opts.open_files(dir)
                end)
            end,
        },
    })
end

local function pick_grep_from_prompted_dir(opts)
    local cwd = expand('~')

    setup_profile(opts.profile or 'fzf-vim', {
        config = opts.config,
    })
    fzf.fzf_exec('fd --hidden --follow --exclude .git --no-ignore --type d', {
        cwd = cwd,
        prompt = 'Directories> ',
        fzf_opts = tbl_deep_extend('force', {
            ['--print-query'] = true,
        }, opts.fzf_opts or {}),
        actions = {
            ['enter'] = function(selected, picker_opts)
                local query = trim(picker_opts.last_query or '')
                local dir = query == '' and cwd or selected[1] and normalize_dir(selected[1], picker_opts.cwd)
                if not dir then
                    return
                end

                local stat = fs_stat(dir)
                if not stat or stat.type ~= 'directory' then
                    notify(('Not a directory: %s'):format(dir), warn)
                    return
                end

                schedule(function()
                    opts.open_grep(dir)
                end)
            end,
        },
    })
end

function pickers.files_prompt_dir()
    pick_files_from_prompted_dir({
        open_files = open_files_in_dir,
    })
end

function pickers.files_prompt_dir_vsplit()
    pick_files_from_prompted_dir({
        files = file_vsplit_config,
        open_files = open_vsplit_files_in_dir,
    })
end

function pickers.files_prompt_dir_fast()
    pick_files_from_prompted_dir({
        profile = 'max-perf',
        files = fast_file_config,
        config = fast_config,
        fzf_opts = {
            ['--ansi'] = false,
        },
        open_files = open_fast_files_in_dir,
    })
end

function pickers.files_prompt_dir_fast_vsplit()
    pick_files_from_prompted_dir({
        profile = 'max-perf',
        files = fast_file_vsplit_config,
        config = fast_config,
        fzf_opts = {
            ['--ansi'] = false,
        },
        open_files = open_fast_vsplit_files_in_dir,
    })
end

function pickers.live_grep_prompt_dir()
    pick_grep_from_prompted_dir({
        open_grep = open_live_grep_in_dir,
    })
end

function pickers.live_grep_prompt_dir_fast()
    pick_grep_from_prompted_dir({
        profile = 'max-perf',
        config = fast_config,
        fzf_opts = {
            ['--ansi'] = false,
        },
        open_grep = open_fast_live_grep_in_dir,
    })
end

create_user_command('Diff', pickers.diff_buffers, {
    desc = 'Diff current buffer with selected buffers',
})

require('config.keymaps').setup_fzf_lua(pickers)

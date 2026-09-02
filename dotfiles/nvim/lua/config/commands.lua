local cmd = vim.cmd
local buf_delete = vim.api.nvim_buf_delete
local buf_is_valid = vim.api.nvim_buf_is_valid
local buf_set_lines = vim.api.nvim_buf_set_lines
local buf_set_name = vim.api.nvim_buf_set_name
local create_user_command = vim.api.nvim_create_user_command
local get_current_buf = vim.api.nvim_get_current_buf
local get_current_win = vim.api.nvim_get_current_win
local set_current_win = vim.api.nvim_set_current_win
local set_option_value = vim.api.nvim_set_option_value
local win_get_cursor = vim.api.nvim_win_get_cursor
local win_set_cursor = vim.api.nvim_win_set_cursor
local exec2 = vim.api.nvim_exec2
local split = vim.split
local list_extend = vim.list_extend
local notify = vim.notify
local warn = vim.log.levels.WARN
local err_level = vim.log.levels.ERROR
local concat = table.concat
local sort = table.sort
local expand = vim.fn.expand
local setreg = vim.fn.setreg
local confirm = vim.fn.confirm
local winsaveview = vim.fn.winsaveview
local winrestview = vim.fn.winrestview
local format = string.format
local keymap_set = vim.keymap.set
local ipairs = ipairs
local pairs = pairs
local pcall = pcall

local function set_buffer_options(buf, options)
    local option_opts = { buf = buf }

    for name, value in pairs(options) do
        set_option_value(name, value, option_opts)
    end
end

local split_plain = { plain = true }
local exec_output = { output = true }
local force_delete = { force = true }
local no_messages = { 'No messages.' }

create_user_command('Scratch', function()
    cmd('botright 10new')

    local buf = get_current_buf()
    local options = {
        filetype = 'scratch',
        buftype = 'nofile',
        bufhidden = 'wipe',
        swapfile = false,
        modifiable = true,
    }

    set_buffer_options(buf, options)
end, { desc = 'Open a scratch buffer' })

create_user_command('DiffOrig', function()
    local source_win = get_current_win()

    cmd('leftabove vnew')
    set_buffer_options(get_current_buf(), {
        buftype = 'nofile',
        bufhidden = 'wipe',
        swapfile = false,
    })

    cmd('read ++edit #')
    cmd('1delete _')
    cmd.diffthis()

    set_current_win(source_win)
    cmd.diffthis()
end, { desc = 'Diff current buffer against the file on disk' })

create_user_command('ClearTrailing', function()
    local view = winsaveview()

    cmd([[keeppatterns %s/[ \t]\+$//e]])
    winrestview(view)
end, { desc = 'Remove trailing whitespace from the current buffer' })

create_user_command('Messages', function()
    local output = exec2('messages', exec_output).output
    local lines = output ~= '' and split(output, '\n', split_plain) or no_messages

    cmd('botright 12new')

    local buf = get_current_buf()
    local options = {
        filetype = 'messages',
        buftype = 'nofile',
        bufhidden = 'wipe',
        swapfile = false,
        modifiable = true,
    }

    set_buffer_options(buf, options)

    pcall(buf_set_name, buf, 'Messages')
    buf_set_lines(buf, 0, -1, false, lines)
    set_option_value('modifiable', false, { buf = buf })
    set_option_value('readonly', true, { buf = buf })
    keymap_set('n', 'q', '<Cmd>close<CR>', {
        buffer = buf,
        silent = true,
        desc = 'Close messages',
    })
    win_set_cursor(0, { #lines, 0 })
end, { desc = 'Open message history' })

create_user_command('Notifications', function()
    local ok, mini_notify = pcall(require, 'mini.notify')
    if not ok then
        notify('mini.notify is not available', warn)
        return
    end

    cmd('botright 12split')
    mini_notify.show_history()

    local buf = get_current_buf()
    set_option_value('buflisted', false, { buf = buf })
    set_option_value('bufhidden', 'wipe', { buf = buf })

    keymap_set('n', 'q', '<Cmd>close<CR>', {
        buffer = buf,
        silent = true,
        desc = 'Close notifications',
    })
end, { desc = 'Open notification history' })

local function copy_current_buffer_path(modifier)
    local path = expand('%' .. modifier)
    if path == '' then
        notify('Current buffer has no file path', warn)
        return
    end

    setreg('+', path)
    notify('Copied: ' .. path)
end

create_user_command('CopyRelativePath', function()
    copy_current_buffer_path(':.')
end, { desc = 'Copy current buffer relative path to clipboard' })

create_user_command('CopyFullPath', function()
    copy_current_buffer_path(':p')
end, { desc = 'Copy current buffer full path to clipboard' })

local terminal

create_user_command('TermFloat', function()
    terminal = terminal or require('config.terminal')
    terminal.toggle_float()
end, { desc = 'Toggle floating terminal' })

create_user_command('TermBottom', function()
    terminal = terminal or require('config.terminal')
    terminal.toggle_bottom()
end, { desc = 'Toggle bottom terminal' })

create_user_command('TermLazygit', function()
    terminal = terminal or require('config.terminal')
    terminal.toggle_lazygit()
end, { desc = 'Toggle lazygit terminal' })

local pack = require('config.pack')

create_user_command('PackList', function()
    local names = pack.names()
    local lines = { 'Installed plugins: ' .. #names }

    list_extend(lines, names)
    cmd('botright 12new')

    local buf = get_current_buf()
    buf_set_name(buf, 'PackList')

    local options = {
        filetype = 'packlist',
        buftype = 'nofile',
        bufhidden = 'wipe',
        swapfile = false,
        modifiable = true,
    }

    set_buffer_options(buf, options)

    buf_set_lines(buf, 0, -1, false, lines)
    set_option_value('modifiable', false, { buf = buf })
end, { desc = 'List plugins managed by vim.pack' })

local function plugin_label(plugin)
    local state = plugin.active and 'active' or 'inactive'
    return format('%s (%s) - %s', plugin.spec.name, state, plugin.path)
end

local function sort_by_plugin_name(left, right)
    return left.spec.name < right.spec.name
end

local function resolve_pack_args(args, on_match)
    local names, seen, errors = {}, {}, {}

    for _, query in ipairs(args) do
        local matches = pack.find(query)
        local count = #matches

        if count == 0 then
            errors[#errors + 1] = 'No installed plugin matches: ' .. query
        elseif count > 1 then
            local labels = {}
            for index, plugin in ipairs(matches) do
                labels[index] = plugin_label(plugin)
            end

            errors[#errors + 1] = 'Ambiguous plugin "' .. query .. '":\n' .. concat(labels, '\n')
        else
            on_match(matches[1], names, seen, errors)
        end
    end

    return names, errors
end

local function resolve_pack_update_args(args)
    local names, errors = resolve_pack_args(args, function(plugin, names, seen)
        local name = plugin.spec.name
        if not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end)

    if #errors > 0 then
        notify('PackUpdate aborted:\n' .. concat(errors, '\n\n'), warn)
        return nil
    end

    return names
end

create_user_command('PackUpdate', function(command)
    if #command.fargs == 0 then
        pack.update()
        return
    end

    local names = resolve_pack_update_args(command.fargs)
    if names then
        pack.update(names)
    end
end, {
    complete = function()
        return pack.names()
    end,
    desc = 'Update plugins managed by vim.pack',
    nargs = '*',
})

local function confirm_delete(names)
    local message = 'Delete plugin'
    if #names == 1 then
        message = message .. ' "' .. names[1] .. '"?'
    else
        message = message .. 's: ' .. concat(names, ', ') .. '?'
    end

    return confirm(message, '&Yes\n&No', 2) == 1
end

local function delete_plugins(names, opts)
    if not confirm_delete(names) then
        return false
    end

    local ok, err = pcall(pack.delete, names, opts)
    if not ok then
        notify('PackDelete failed: ' .. err, err_level)
        return false
    end

    notify('Deleted: ' .. concat(names, ', '))
    return true
end

local function resolve_pack_delete_args(args, force)
    local names, errors = resolve_pack_args(args, function(plugin, names, seen, errors)
        local name = plugin.spec.name

        if plugin.active and not force then
            errors[#errors + 1] = name ..
            ' is active. Remove its vim.pack.add() spec first, or use :PackDelete! ' .. name
        elseif not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end)

    if #errors > 0 then
        notify('PackDelete aborted:\n' .. concat(errors, '\n\n'), warn)
        return nil
    end

    return names
end

local function open_pack_delete_picker()
    local plugins = {}

    for _, plugin in ipairs(pack.list()) do
        if not plugin.active then
            plugins[#plugins + 1] = plugin
        end
    end

    sort(plugins, sort_by_plugin_name)

    if #plugins == 0 then
        notify('No inactive installed plugins to delete')
        return
    end

    cmd('botright 12new')
    local buf = get_current_buf()
    local buf_options = vim.bo[buf]
    local selected = {}

    local function render()
        local lines = {
            'PackDelete: <Space> toggle, d delete selected, q close',
            '',
        }

        for index, plugin in ipairs(plugins) do
            local mark = selected[index] and '[x]' or '[ ]'
            lines[#lines + 1] = format('%s %s - %s', mark, plugin.spec.name, plugin.path)
        end

        buf_options.modifiable = true
        buf_set_lines(buf, 0, -1, false, lines)
        buf_options.modifiable = false
    end

    local function current_index()
        local line = win_get_cursor(0)[1]
        local index = line - 2
        if index < 1 or index > #plugins then
            return nil
        end
        return index
    end

    local function toggle_current()
        local index = current_index()
        if not index then
            return
        end

        selected[index] = not selected[index]
        render()
        win_set_cursor(0, { index + 2, 0 })
    end

    local function delete_selected()
        local names = {}
        for index, plugin in ipairs(plugins) do
            if selected[index] then
                names[#names + 1] = plugin.spec.name
            end
        end

        if #names == 0 then
            notify('No plugins selected', warn)
            return
        end

        if delete_plugins(names) and buf_is_valid(buf) then
            buf_delete(buf, force_delete)
        end
    end

    buf_options.filetype = 'packdelete'
    buf_options.buftype = 'nofile'
    buf_options.bufhidden = 'wipe'
    buf_options.swapfile = false
    buf_options.modifiable = false

    keymap_set('n', '<Space>', toggle_current, { buffer = buf, desc = 'Toggle plugin selection' })
    keymap_set('n', 'd', delete_selected, { buffer = buf, desc = 'Delete selected plugins' })
    keymap_set('n', 'q', '<cmd>close<CR>', { buffer = buf, desc = 'Close PackDelete' })

    render()
    win_set_cursor(0, { 3, 0 })
end

create_user_command('PackDelete', function(command)
    if #command.fargs == 0 then
        open_pack_delete_picker()
        return
    end

    local names = resolve_pack_delete_args(command.fargs, command.bang)
    if names then
        delete_plugins(names, command.bang and force_delete or nil)
    end
end, {
    bang = true,
    complete = function()
        return pack.names()
    end,
    desc = 'Delete plugins managed by vim.pack',
    nargs = '*',
})

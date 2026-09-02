local M = {}

local api = vim.api
local defer_fn = vim.defer_fn
local fn = vim.fn
local notify = vim.notify
local trim = vim.trim
local error_level = vim.log.levels.ERROR
local warn_level = vim.log.levels.WARN
local sort = table.sort
local fnamemodify = fn.fnamemodify
local confirm = fn.confirm
local setreg = fn.setreg

local save_changes = 1
local discard_changes = 2
local confirm_delete = 1

local function configured_directory()
    return MiniSessions.config.directory ~= '' and MiniSessions.config.directory or vim.g.user_project_session_dir
end

local function normalize_name(name)
    name = trim(name or '')

    if name == '' then
        notify('Session name cannot be empty', error_level)
        return nil
    end

    if name:find('[\\/]') then
        notify('Session name cannot contain path separators', error_level)
        return nil
    end

    return name
end

local function modified_listed_buffers()
    local buffers = {}

    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        if vim.bo[bufnr].modified and vim.bo[bufnr].buflisted then
            buffers[#buffers + 1] = bufnr
        end
    end

    return buffers
end

local function buffer_label(bufnr)
    local name = api.nvim_buf_get_name(bufnr)
    return name ~= '' and fnamemodify(name, ':~:.') or ('[No Name] ' .. bufnr)
end

local function write_modified_buffers(buffers)
    for _, bufnr in ipairs(buffers) do
        local ok, err = pcall(api.nvim_buf_call, bufnr, function()
            vim.cmd.write()
        end)

        if not ok then
            notify(('Could not save %s: %s'):format(buffer_label(bufnr), err), error_level)
            return false
        end
    end

    return true
end

local function confirm_unsaved_buffers()
    local buffers = modified_listed_buffers()
    if #buffers == 0 then
        return true, false
    end

    local choice = confirm(
        ('Save changes before switching sessions?\n\nModified buffers: %d'):format(#buffers),
        '&Save\n&Discard\n&Cancel',
        3
    )

    if choice == save_changes then
        return write_modified_buffers(buffers), false
    end

    if choice == discard_changes then
        return true, true
    end

    return false, false
end

local function read_internal(internal, opts)
    if not (MiniSessions.detected or {})[internal] then
        notify('No local session: ' .. internal, warn_level)
        return
    end

    local should_switch, force = confirm_unsaved_buffers()
    if not should_switch then
        return
    end

    opts = vim.tbl_extend('force', opts or {}, { force = force })

    defer_fn(function()
        local ok, err = pcall(MiniSessions.read, internal, opts)
        if not ok then
            notify(('Could not switch session: %s'):format(err), error_level)
            return
        end

        notify('Session changed to: ' .. (M.display_name(internal) or internal))
    end, 25)
end

local function delete_internal(internal)
    local display = M.display_name(internal)
    if not display then
        notify('No local session: ' .. internal, warn_level)
        return false
    end

    if M.current_display_name() == display then
        notify('Cannot delete the active session: ' .. display, warn_level)
        return false
    end

    if confirm(('Delete session "%s"?'):format(display), '&Delete\n&Cancel', 2) ~= confirm_delete then
        return false
    end

    local ok, err = pcall(MiniSessions.delete, internal, { force = true })
    if not ok then
        notify(('Could not delete session "%s": %s'):format(display, err), error_level)
        return false
    end

    return true
end

local function create(name)
    local internal = M.internal_name(name)
    if not internal then
        return false
    end

    if (MiniSessions.detected or {})[internal] then
        notify('Session already exists: ' .. name, warn_level)
        return false
    end

    local directory = configured_directory()
    if not directory or directory == '' then
        notify('No session directory configured', error_level)
        return false
    end

    local mkdir_ok, mkdir_err = pcall(fn.mkdir, directory, 'p')
    if not mkdir_ok or fn.isdirectory(directory) ~= 1 then
        notify(('Could not create session directory "%s": %s'):format(directory, mkdir_err or 'not a directory'), error_level)
        return false
    end

    MiniSessions.config.directory = directory

    local ok, err = pcall(MiniSessions.write, internal)
    if not ok then
        notify(('Could not create session "%s": %s'):format(name, err), error_level)
        return false
    end

    notify('Session changed to: ' .. name)
    return true
end

function M.directory()
    return configured_directory()
end

function M.show_directory()
    local directory = M.directory()
    setreg('+', directory)
    notify(('Directory: %s'):format(fnamemodify(directory, ':~')))
end

function M.internal_name(name)
    return normalize_name(name)
end

function M.display_name(internal_name)
    return (MiniSessions.detected or {})[internal_name] and internal_name or nil
end

function M.current_display_name()
    local this_session = vim.v.this_session
    if this_session == '' then
        return nil
    end

    local current = fnamemodify(this_session, ':t')
    return M.display_name(current)
end

function M.project_sessions()
    local sessions = {}

    for name, data in pairs(MiniSessions.detected or {}) do
        sessions[#sessions + 1] = {
            display = name,
            internal = name,
            modify_time = data.modify_time or 0,
        }
    end

    sort(sessions, function(left, right)
        if left.modify_time ~= right.modify_time then
            return left.modify_time > right.modify_time
        end
        return left.display < right.display
    end)

    return sessions
end

function M.project_sessions_for_picker()
    local project_sessions = M.project_sessions()
    local current = M.current_display_name()

    if #project_sessions < 2 or not current or project_sessions[2].display == current then
        return project_sessions
    end

    for index, session in ipairs(project_sessions) do
        if session.display == current then
            table.remove(project_sessions, index)
            table.insert(project_sessions, 2, session)
            break
        end
    end

    return project_sessions
end

function M.write(name)
    return create(name)
end

function M.read(name)
    local internal = M.internal_name(name)
    if not internal then
        return
    end

    read_internal(internal)
end

function M.read_internal(internal)
    read_internal(internal)
end

function M.delete_internal(internal)
    return delete_internal(internal)
end

function M.create(name)
    return create(name)
end

return M

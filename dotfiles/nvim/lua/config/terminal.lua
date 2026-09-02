local M = {}

local terminals = {
    bottom = { buf = nil, win = nil, job = nil, exited = false },
    float = { buf = nil, win = nil, job = nil, exited = false },
    lazygit = { buf = nil, win = nil, job = nil, exited = false },
}

local bottom_terminal = terminals.bottom
local float_terminal = terminals.float
local lazygit_terminal = terminals.lazygit
local force_delete = { force = true }
local buf_is_valid = vim.api.nvim_buf_is_valid
local buf_delete = vim.api.nvim_buf_delete
local create_buf = vim.api.nvim_create_buf
local get_current_buf = vim.api.nvim_get_current_buf
local get_current_win = vim.api.nvim_get_current_win
local open_win = vim.api.nvim_open_win
local set_current_win = vim.api.nvim_set_current_win
local win_close = vim.api.nvim_win_close
local win_is_valid = vim.api.nvim_win_is_valid
local win_set_buf = vim.api.nvim_win_set_buf
local cmd = vim.cmd
local schedule = vim.schedule
local keycode = vim.keycode
local keymap_set = vim.keymap.set
local bo = vim.bo
local wo = vim.wo
local o = vim.o
local getenv = os.getenv
local min = math.min
local max = math.max
local floor = math.floor
local win_findbuf = vim.fn.win_findbuf
local jobstart = vim.fn.jobstart
local ctrl_d = keycode('<C-d>')

local function valid_terminal(term)
    return term.buf
        and not term.exited
        and buf_is_valid(term.buf)
        and bo[term.buf].buftype == 'terminal'
end

local function valid_win(win)
    return win and win_is_valid(win)
end

local function visible_win(buf)
    return buf and buf_is_valid(buf) and win_findbuf(buf)[1]
end

local function shell()
    return o.shell ~= '' and o.shell or getenv('SHELL') or 'sh'
end

local function configure_buf(buf)
    bo[buf].bufhidden = 'hide'
    bo[buf].buflisted = false
    bo[buf].swapfile = false
    keymap_set('n', '<C-d>', function()
        require('config.terminal').close_current()
    end, { buffer = buf, desc = 'Close managed terminal' })
end

local function configure_win(win)
    wo[win].number = false
    wo[win].relativenumber = false
    wo[win].signcolumn = 'no'
end

local function reset_terminal(term)
    if term.buf and buf_is_valid(term.buf) then
        buf_delete(term.buf, force_delete)
    end

    term.buf = nil
    term.win = nil
    term.job = nil
    term.exited = false
end

local function terminal_for_buf(buf)
    if bottom_terminal.buf == buf then
        return bottom_terminal
    end

    if float_terminal.buf == buf then
        return float_terminal
    end

    if lazygit_terminal.buf == buf then
        return lazygit_terminal
    end
end

local function start_terminal(term, command)
    if valid_terminal(term) then
        return
    end

    term.exited = false
    local job
    job = jobstart(command or shell(), {
        term = true,
        on_exit = function()
            if term.job == job then
                term.exited = true
            end
        end,
    })
    term.job = job
end

local function enter_terminal(win)
    set_current_win(win)
    configure_win(win)
    cmd.startinsert()
end

local function toggle_floating_terminal(term, command)
    if valid_win(term.win) then
        win_close(term.win, false)
        term.win = nil
        return
    end

    local columns = o.columns
    local lines = o.lines
    local width = min(max(40, floor(columns * 0.8)), max(1, columns))
    local height = min(max(12, floor(lines * 0.8)), max(1, lines - 2))

    if term.exited then
        reset_terminal(term)
    end

    if not term.buf or not buf_is_valid(term.buf) then
        term.buf = create_buf(false, true)
        configure_buf(term.buf)
    end

    term.win = open_win(term.buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = floor((lines - height) / 2),
        col = floor((columns - width) / 2),
        style = 'minimal',
        border = 'rounded',
    })

    start_terminal(term, command)
    enter_terminal(term.win)
end

function M.toggle_float()
    toggle_floating_terminal(terminals.float)
end

function M.toggle_lazygit()
    toggle_floating_terminal(terminals.lazygit, 'lazygit')
end

function M.toggle_bottom()
    local term = terminals.bottom
    local win = valid_win(term.win) and term.win or visible_win(term.buf)

    if term.exited then
        reset_terminal(term)
        win = nil
    end

    if win then
        win_close(win, false)
        term.win = nil
        return
    end

    if valid_terminal(term) then
        cmd('botright 12split')
        win_set_buf(0, term.buf)
    else
        cmd('botright 12new')
        term.buf = get_current_buf()
        configure_buf(term.buf)
    end

    term.win = get_current_win()
    start_terminal(term)
    enter_terminal(term.win)
end

local function close_buf(buf)
    local term = terminal_for_buf(buf)

    if not term then
        return false
    end

    reset_terminal(term)
    return true
end

function M.close_current()
    return close_buf(get_current_buf())
end

function M.close_current_key()
    local buf = get_current_buf()

    if terminal_for_buf(buf) then
        schedule(function()
            close_buf(buf)
        end)

        return ''
    end

    return ctrl_d
end

return M

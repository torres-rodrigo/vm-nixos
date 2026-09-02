local M = {}

local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local treesitter = vim.treesitter
local wo = vim.wo
local buf_line_count = api.nvim_buf_line_count
local get_current_win = api.nvim_get_current_win
local win_get_cursor = api.nvim_win_get_cursor
local win_set_cursor = api.nvim_win_set_cursor
local pcall = pcall

local root_node_types = {
    chunk = true,
    program = true,
    source_file = true,
    translation_unit = true,
}

local function normal(keys)
    cmd.normal({ keys, bang = true })
end

local function current_node()
    local ok, node = pcall(treesitter.get_node, { ignore_injections = false })
    return ok and node or nil
end

local function is_foldable_node(node, line_count)
    if not node or not node:named() or not node:parent() then
        return false
    end

    local start_row, _, end_row = node:range()
    if end_row <= start_row then
        return false
    end

    return not (start_row == 0 and end_row >= line_count - 1) and not root_node_types[node:type()]
end

local function fold_start_for_node(node)
    local start_row, _, end_row = node:range()

    for lnum = start_row + 1, end_row + 1 do
        local previous_level = lnum > 1 and fn.foldlevel(lnum - 1) or 0
        if fn.foldlevel(lnum) > previous_level then
            return lnum
        end
    end
end

local function with_cursor(lnum, callback)
    local win = get_current_win()
    local cursor = win_get_cursor(win)
    local view = fn.winsaveview()

    win_set_cursor(win, { lnum, 0 })
    callback()
    fn.winrestview(view)

    if fn.foldclosed(cursor[1]) == -1 then
        pcall(win_set_cursor, win, cursor)
    end
end

local function close_fold()
    normal('zc')
end

local function open_fold()
    normal('zo')
end

local function enclosing_nodes()
    local nodes = {}
    local line_count = buf_line_count(0)
    local node = current_node()

    while node do
        if is_foldable_node(node, line_count) then
            nodes[#nodes + 1] = node
        end
        node = node:parent()
    end

    return nodes
end

local function close_lnum(lnum)
    if fn.foldclosed(lnum) ~= -1 then
        return false
    end

    with_cursor(lnum, close_fold)

    return fn.foldclosed(lnum) ~= -1
end

local function open_lnum(lnum)
    if fn.foldclosed(lnum) == -1 then
        return false
    end

    with_cursor(lnum, open_fold)

    return fn.foldclosed(lnum) == -1
end

local function close_node(node)
    local lnum = fold_start_for_node(node)
    if not lnum then
        return false
    end

    return close_lnum(lnum)
end

local function open_node(node)
    local lnum = fold_start_for_node(node)
    if not lnum then
        return false
    end

    return open_lnum(lnum)
end

function M.enable_treesitter(bufnr)
    if not treesitter.highlighter.active[bufnr] then
        return
    end

    wo[0][0].foldmethod = 'expr'
    wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'

    local view = fn.winsaveview()
    normal('zx')
    fn.winrestview(view)
end

function M.toggle_current_scope()
    local nodes = enclosing_nodes()
    for index = 1, #nodes do
        local node = nodes[index]
        local lnum = fold_start_for_node(node)
        if lnum then
            if fn.foldclosed(lnum) == -1 then
                if close_lnum(lnum) then
                    return
                end
            elseif open_lnum(lnum) then
                return
            end
        end
    end

    normal('za')
end

function M.close_next_enclosing_node()
    local nodes = enclosing_nodes()
    for index = 1, #nodes do
        local node = nodes[index]
        if close_node(node) then
            return
        end
    end

    normal('zc')
end

function M.open_enclosing_node()
    local nodes = enclosing_nodes()
    for index = 1, #nodes do
        local node = nodes[index]
        if open_node(node) then
            return
        end
    end

    normal('zo')
end

return M

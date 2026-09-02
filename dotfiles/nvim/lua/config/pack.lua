local M = {}

local api = vim.api
local pack = vim.pack
local trim = vim.trim
local error = error
local pairs = pairs
local pcall = pcall
local require = require
local sort = table.sort
local type = type
local str_find = string.find
local str_gsub = string.gsub
local str_lower = string.lower
local str_match = string.match

local group = api.nvim_create_augroup('user_pack', { clear = true })

local local_fields = {
    module = true,
    opts = true,
    setup = true,
}

local function ensure_pack()
    if not pack then
        error('config.pack requires Neovim with vim.pack support', 3)
    end
end

local function github_url(src)
    if str_match(src, '^%w[%w+.-]*://') then
        return src
    end

    return 'https://github.com/' .. src
end

local function plugin_name(spec)
    local src = type(spec) == 'string' and spec or spec.src
    if not src then
        return nil
    end

    return str_match(str_gsub(src, '%.git$', ''), '[^/]+$')
end

local function module_name(spec)
    if type(spec) == 'table' and spec.module then
        return spec.module
    end

    local name = plugin_name(spec)
    return name and str_gsub(name, '%.nvim$', '') or nil
end

local function normalize_spec(spec)
    if type(spec) == 'string' then
        return github_url(spec)
    end

    if type(spec) ~= 'table' then
        error('plugin spec must be a string or table', 3)
    end

    local normalized = {}
    for key, value in pairs(spec) do
        if not local_fields[key] then
            normalized[key] = value
        end
    end

    if normalized.src then
        normalized.src = github_url(normalized.src)
    end

    return normalized
end

local function normalize_specs(specs)
    if type(specs) ~= 'table' then
        error('plugin specs must be a list', 3)
    end

    local normalized = {}
    for index = 1, #specs do
        normalized[index] = normalize_spec(specs[index])
    end
    return normalized
end

local function setup_plugin(spec)
    if type(spec) ~= 'table' or spec.setup == false then
        return
    end

    local name = module_name(spec)
    if not name then
        return
    end

    local ok, mod = pcall(require, name)
    if not ok or type(mod.setup) ~= 'function' then
        return
    end

    local opts = type(spec.opts) == 'function' and spec.opts() or spec.opts
    mod.setup(opts or {})
end

function M.add(specs)
    ensure_pack()
    pack.add(normalize_specs(specs))

    for index = 1, #specs do
        setup_plugin(specs[index])
    end
end

function M.list()
    ensure_pack()
    return pack.get(nil, { info = false })
end

function M.names()
    local plugins = M.list()
    local names = {}
    for index = 1, #plugins do
        names[index] = plugins[index].spec.name
    end

    sort(names)
    return names
end

function M.find(query)
    query = trim(query or '')
    if query == '' then
        return {}
    end

    local query_lower = str_lower(query)
    local exact, partial = {}, {}

    local plugins = M.list()
    for index = 1, #plugins do
        local plugin = plugins[index]
        local name = plugin.spec.name or ''
        local src = plugin.spec.src or ''
        local name_lower = str_lower(name)

        if name_lower == query_lower then
            exact[#exact + 1] = plugin
        elseif str_find(name_lower, query_lower, 1, true) or str_find(str_lower(src), query_lower, 1, true) then
            partial[#partial + 1] = plugin
        end
    end

    return #exact > 0 and exact or partial
end

function M.delete(names, opts)
    ensure_pack()
    if type(names) ~= 'table' or #names == 0 then
        return
    end

    pack.del(names, opts or {})
end

function M.update(names)
    ensure_pack()
    pack.update(names)
end

function M.add_on_event(event, specs)
    api.nvim_create_autocmd(event, {
        group = group,
        once = true,
        callback = function()
            M.add(specs)
        end,
    })
end

function M.add_on_filetype(filetypes, specs)
    api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = filetypes,
        once = true,
        callback = function()
            M.add(specs)
        end,
    })
end

function M.on_update(name, callback)
    api.nvim_create_autocmd('PackChanged', {
        group = group,
        desc = 'Run plugin update hook for ' .. name,
        callback = function(args)
            local data = args.data or {}
            local spec = data.spec or {}

            if spec.name ~= name or (data.kind ~= 'install' and data.kind ~= 'update') then
                return
            end

            callback(data)
        end,
    })
end

return M

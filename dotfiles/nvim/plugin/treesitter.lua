local pack = require('config.pack')

local parsers = {
    'bash',
    'c',
    'css',
    'go',
    'html',
    'json',
    'lua',
    'markdown',
    'markdown_inline',
    'odin',
    'query',
    'toml',
    'yaml',
}

pack.add({
    {
        src = 'nvim-treesitter/nvim-treesitter',
        setup = false,
    },
})

-- Main-branch nvim-treesitter stores queries under runtime/queries.
local init = vim.api.nvim_get_runtime_file('lua/nvim-treesitter/init.lua', false)[1]
if init then
    vim.opt.runtimepath:prepend(vim.fn.fnamemodify(init, ':h:h:h') .. '/runtime')
end

local function has_tree_sitter_cli()
    return vim.fn.executable('tree-sitter') == 1
end

local function missing_parsers()
    local installed = {}
    for _, parser in ipairs(require('nvim-treesitter.config').get_installed()) do
        installed[parser] = true
    end

    return vim.tbl_filter(function(parser)
        return not installed[parser]
    end, parsers)
end

local function install_missing_parsers()
    if not has_tree_sitter_cli() then
        return
    end

    local to_install = missing_parsers()
    if #to_install > 0 then
        require('nvim-treesitter').install(to_install)
    end
end

install_missing_parsers()

pack.on_update('nvim-treesitter', function()
    if not has_tree_sitter_cli() then
        vim.notify('tree-sitter CLI is required to install or update parsers', vim.log.levels.WARN)
        return
    end

    local treesitter = require('nvim-treesitter')
    treesitter.install(parsers):wait(300000)
    treesitter.update():wait(300000)
end)

local filetypes = {}
for _, parser in ipairs(parsers) do
    for _, filetype in ipairs(vim.treesitter.language.get_filetypes(parser)) do
        filetypes[#filetypes + 1] = filetype
    end
end

local folds = require('config.folds')

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('user_treesitter', { clear = true }),
    desc = 'Start Treesitter highlighting',
    pattern = filetypes,
    callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then
            folds.enable_treesitter(args.buf)
        end
    end,
})

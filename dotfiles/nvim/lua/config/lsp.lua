local create_augroup = vim.api.nvim_create_augroup
local create_autocmd = vim.api.nvim_create_autocmd
local buf_is_valid = vim.api.nvim_buf_is_valid
local b = vim.b
local lsp = vim.lsp
local lsp_buf = vim.lsp.buf
local lsp_handlers = lsp.handlers

local group = create_augroup('user_lsp', { clear = true })
local border = { border = 'rounded' }
local document_highlight_handler = lsp_handlers['textDocument/documentHighlight']

lsp_handlers['textDocument/documentHighlight'] = function(err, result, ctx, config)
    if not ctx or not buf_is_valid(ctx.bufnr) then
        return
    end

    return document_highlight_handler(err, result, ctx, config)
end

local function setup_document_highlight(client, bufnr)
    if b[bufnr].lsp_document_highlight then
        return
    end

    if not client:supports_method('textDocument/documentHighlight', bufnr) then
        return
    end

    b[bufnr].lsp_document_highlight = true

    create_autocmd({ 'CursorHold', 'InsertLeave' }, {
        group = group,
        buffer = bufnr,
        desc = 'Highlight LSP symbol references',
        callback = lsp_buf.document_highlight,
    })

    create_autocmd({ 'CursorMoved', 'InsertEnter' }, {
        group = group,
        buffer = bufnr,
        desc = 'Clear LSP symbol references',
        callback = lsp_buf.clear_references,
    })
end

create_autocmd('LspAttach', {
    group = group,
    desc = 'Configure LSP buffer behavior',
    callback = function(args)
        local client = lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        require('config.keymaps').setup_lsp(client, args.buf, border)
        setup_document_highlight(client, args.buf)
    end,
})

create_autocmd('LspDetach', {
    group = group,
    desc = 'Clear LSP symbol references',
    callback = function(args)
        lsp_buf.clear_references()
        b[args.buf].lsp_document_highlight = false
    end,
})

lsp.enable({
    'lua_ls',
    'bashls',
    'jsonls',
    'yamlls',
    'gopls',
    'clangd',
    'taplo',
    'ols',
    'nixd',
})

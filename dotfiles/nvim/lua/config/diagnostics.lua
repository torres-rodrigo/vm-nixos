local diagnostic = vim.diagnostic
local cmd = vim.cmd
local severity = diagnostic.severity

local M = {}
local open_list = { open = true }

M.display = {
    underline = true,
    signs = {
        priority = 9999,
        severity = { severity.ERROR, severity.WARN },
        text = {
            [severity.ERROR] = 'E',
            [severity.WARN] = 'W',
        },
    },
    virtual_lines = { current_line = true },
    virtual_text = {
        current_line = true,
        severity = severity.ERROR,
        prefix = ' ',
        spacing = 2,
        source = 'if_many',
    },
}

local display_enabled = {
    underline = true,
    signs = true,
    virtual_lines = false,
    virtual_text = true,
}

function M.toggle_display(name)
    if M.display[name] == nil then
        return
    end

    display_enabled[name] = not display_enabled[name]
    diagnostic.config({ [name] = display_enabled[name] and M.display[name] or false })
end

function M.open_loclist()
    diagnostic.setloclist(open_list)
    cmd('botright lopen 10')
end

function M.open_qflist()
    diagnostic.setqflist(open_list)
    cmd('botright copen 10')
end

diagnostic.config({
    severity_sort = true,
    update_in_insert = false,
    underline = M.display.underline,
    signs = M.display.signs,
    virtual_text = M.display.virtual_text,
    float = {
        border = 'rounded',
        focusable = false,
        header = '',
        prefix = '',
        source = 'if_many',
        style = 'minimal',
    },
    jump = {
        wrap = false,
    },
})

return M

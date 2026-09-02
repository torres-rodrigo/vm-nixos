vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- This lines are to make the config portable to other directories.
-- nvim -u <PATH>/init.lua
--
-- local config_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
-- vim.opt.runtimepath:prepend(config_dir)
--
-- package.path = table.concat({
--   config_dir .. '/lua/?.lua',
--   config_dir .. '/lua/?/init.lua',
--   package.path,
-- }, ';')
--

vim.loader.enable()

require('config.bootstrap')
require('config.pack')
require('config.options')
require('config.diagnostics')
require('config.keymaps')
require('config.commands')
require('config.autocmds')

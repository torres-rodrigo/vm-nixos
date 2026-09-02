local ok, ui2 = pcall(require, 'vim._core.ui2')
if ok then
    ui2.enable({})
end

local g = vim.g

g.loaded_python3_provider = 0
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

g.loaded_netrwPlugin = 1
g.loaded_tutor_mode_plugin = 1
g.did_install_default_menus = 1
g.loaded_2html_plugin = 1

vim.api.nvim_create_autocmd('UIEnter', {
  group = vim.api.nvim_create_augroup('user_quicker', { clear = true }),
  once = true,
  callback = function()
    require('config.pack').add({
      {
        src = 'stevearc/quicker.nvim',
        setup = false,
      },
    })

    local quicker = require('quicker')
    local keymaps = require('config.keymaps')
    local setup_quicker = keymaps.setup_quicker

    quicker.setup(keymaps.quicker)
    setup_quicker(quicker)
  end,
})

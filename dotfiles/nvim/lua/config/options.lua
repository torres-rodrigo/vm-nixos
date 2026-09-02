local opt = vim.o

-- Globals
vim.g.have_nerd_fonts = true -- Tell UI code that Nerd Font icons are available.

-- Cursor And Mouse
opt.guicursor = '' -- Use Neovim's default terminal cursor shape behavior.
opt.mouse = 'a'    -- Enable mouse support in all modes.
opt.mousescroll = 'ver:1,hor:5'

-- UI
opt.termguicolors = true   -- Enable true-color terminal highlighting.
opt.showmode = false       -- Hide mode text like "-- INSERT --" from the command line.
opt.laststatus = 3         -- Use a single global statusline.
opt.signcolumn = 'yes'     -- Always show the sign column to avoid layout shifts.
opt.number = true          -- Show absolute line numbers.
opt.relativenumber = true  -- Show line numbers relative to the cursor.
opt.winborder = 'rounded'  -- Use rounded borders for built-in floating windows.
opt.shortmess = 'CFOSWaco' -- Reduce noisy command-line messages.
opt.cursorline = true      -- Highlight line
opt.showtabline = 0        -- Never show tabline

-- Windows And Splits
opt.splitbelow = true    -- Open horizontal splits below the current window.
opt.splitright = true    -- Open vertical splits to the right of the current window.
opt.splitkeep = 'screen' -- Reduce scroll jumps when opening splits.
opt.winminwidth = 5      -- Keep windows at least five columns wide.

-- Scrolling And Wrapping
opt.wrap = false        -- Do not visually wrap long lines.
opt.scrolloff = 7       -- Keep context lines visible above and below the cursor.
opt.smoothscroll = true -- Scroll by screen line for smoother movement.

-- Indentation
opt.tabstop = 4        -- Display tab characters as four spaces wide.
opt.softtabstop = 4    -- Make editing tab indentation feel like four spaces.
opt.shiftwidth = 4     -- Use four spaces for each indentation step.
opt.expandtab = true   -- Insert spaces instead of tab characters.
opt.smarttab = true    -- Use shiftwidth when inserting tabs at line starts.
opt.smartindent = true -- Enable simple syntax-aware autoindentation.
opt.shiftround = true  -- Round indentation changes to multiples of shiftwidth.

-- Search And Replace
opt.ignorecase = true    -- Search case-insensitively by default.
opt.smartcase = true     -- Search case-sensitively when the pattern has uppercase.
opt.hlsearch = true      -- Highlight all matches of the current search.
opt.incsearch = true     -- Show search matches while typing the pattern.
opt.inccommand = 'nosplit' -- Preview substitution results in a split.

-- Editing
opt.swapfile = false                         -- Do not create swapfiles for buffers.
opt.backup = false                           -- Do not create backup file
opt.undofile = true                          -- Save undo history to disk so undo works across sessions.
opt.autoread = true                          -- Automatically reload unchanged buffers when files change on disk.
opt.confirm = true                           -- Ask for confirmation instead of failing on unsaved changes.
opt.shada = "'100,<50,s10,:1000,/100,@100,h" -- Keep ShaDa history useful but bounded.
opt.virtualedit = 'block'                    -- Allow block selections past the end of lines.
opt.jumpoptions = 'view'                     -- Restore view when jumping through the jumplist.

-- Diff
vim.opt.diffopt:append({ 'followwrap', 'vertical', 'context:99', 'linematch:60' }) -- Improve built-in diff layout and matching.

-- Grep
opt.grepformat = '%f:%l:%c:%m' -- Parse ripgrep-style file, line, column, message output.
opt.grepprg = 'rg --vimgrep'   -- Use ripgrep for the built-in :grep command.

-- Completion
opt.completeopt = 'menu,menuone,noselect' -- Show completion menu without preselecting an item.
opt.pumheight = 13                        -- Limit popup menu height.
opt.pumblend = 15                         -- Make popup menus slightly transparent.
opt.pumborder = 'rounded'                 -- Draw a rounded border around popup menus.

-- Command-Line Completion
opt.wildignorecase = true               -- Ignore case when completing file and directory names.
opt.wildmode = 'noselect:lastused,full' -- Show the menu before changing the command-line.
opt.wildcharm = 26                      -- Use <C-z> as wildchar inside command-line mappings.
vim.opt.wildoptions:append('fuzzy')     -- Use fuzzy matching for supported command-line completions.

-- Timing
opt.timeoutlen = 900 -- Time in milliseconds to wait for mapped key sequences.
opt.updatetime = 300 -- Idle time before CursorHold and swap/write-triggered events.

-- Folds
opt.foldlevel = 99        -- Keep folds open by default.
opt.foldlevelstart = 99   -- Open all folds when starting to edit a buffer.
opt.foldnestmax = 20      -- Allow deeply nested code folds.
opt.foldmethod = 'indent' -- Create folds from indentation until Treesitter is available.
opt.foldtext = ''         -- Use default line text and highlighting for closed folds.

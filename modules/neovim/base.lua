-----------------------------------------------------------------------------
-- FUNCTIONS

ToggleParedit = function()
  if vim.g.paredit_mode == 0 then
    vim.g.paredit_mode = 1
    print("paredit on")
  else
    vim.g.paredit_mode = 0
    print("paredit off")
  end
  -- Sometimes paredit seems to not get turned back on, this is a workaround
  vim.cmd 'edit'
end

-- See *lua-guide-commands-create*
vim.api.nvim_create_user_command('ResetWorkspace',
  function(_)
    vim.cmd('silent! tabonly')
    vim.cmd('silent! only')
    vim.cmd('silent! %bdelete')
    local buf = vim.api.nvim_get_current_buf()              -- should always be 0
    vim.api.nvim_buf_set_option(buf, "bufhidden", "delete") -- what to do when the buffer is hidden
    vim.api.nvim_buf_set_option(buf, "buflisted", true)     -- include the buffer in the :bnext list
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")   -- nofile means the buffer isn't backed by a file and we control its name
    vim.api.nvim_buf_set_option(buf, "swapfile", false)     -- never swapfiles
  end,
  {
    desc = "Reset all tabs, windows, and buffers",
    force = false,
  }
)

----------------------------------------------------------------------------------
-- OPTIONS

vim.opt.swapfile = false          -- turn swapfiles off
vim.opt.undofile = true           -- save undo history
vim.opt.scrolloff = 10            -- keep cursor centered vertically while scrolling
vim.opt.sidescrolloff = 20        -- How many columns between cursor and edge when scrolling starts horizontally
vim.opt.tabstop = 2               -- Insert 2 spaces for a tab
vim.opt.shiftwidth = 2            -- Change the number of space characters inserted for indentation
vim.opt.expandtab = true          -- Converts tabs to spaces, if false then nvim-lsp formatting will always use tabs :/
vim.opt.smartindent = true        -- Makes indenting smart
vim.opt.updatetime = 300          -- Faster completion
vim.opt.timeout = false           -- Wait indefinitely for keymap continuation
vim.opt.clipboard = 'unnamedplus' -- Copy paste between vim and everything else
vim.opt.wrap = false              -- Display long lines as just one line
vim.opt.pumheight = 10            -- Makes popup menu smaller
vim.opt.showtabline = 2           -- Always show tabs
vim.opt.showmode = false          -- We don't need to see things like -- INSERT -- anymore
vim.opt.signcolumn = 'yes'        -- Always show the signcolumn in the number column
vim.opt.splitbelow = true         -- Horizontal splits will automatically be below
vim.opt.splitright = true         -- Vertical splits will automatically be to the right
vim.opt.linebreak = true          -- Break lines at word boundaries for readability
vim.opt.bg = 'dark'               -- Have dark background by default
vim.opt.whichwrap = 'h,l'         -- Allow left/right scrolling to jump lines
vim.opt.numberwidth = 1           -- make minimum width for number column smallest value so it doesn't take up much room
vim.opt.termguicolors = true      -- enable full color support
vim.opt.ignorecase = true         -- ignore case when searching
vim.opt.smartcase = true          -- don't ignore case when searching with capital letters
vim.opt.completeopt = {           -- Completion behavior
  "menu",
  "menuone",
  "popup",
  "noselect",
  "preview",
  "fuzzy"
}

----------------------------------------------------------------------------------------
-- GLOBALS

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.netrw_fastbrowse = 0;
vim.g['clojure_fuzzy_indent_patterns'] = { '^with', '^def', '^let', '^try', '^do' }
vim.g['clojure_align_multiline_strings'] = 0
vim.g['clojure_align_subforms'] = 1
vim.g['clojure_maxlines'] = 0
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#denols
vim.g.markdown_fenced_languages = {
  "ts=typescript"
}

vim.cmd 'filetype plugin indent on' -- Enables filetype detection and features
vim.filetype.add({
  extension = {
    age = 'age',
  },
})

----------------------------------------------------------------------------------------
-- MAPPINGS

-- TEXT MANIPULATION
-- Yank word under cursor
vim.keymap.set('n', 'Y', 'viwy')
vim.keymap.set({ 'n', 'x' }, '<leader>/', '<cmd>nohlsearch<cr>')

-- BUFFERS
-- <c-^> is buffer back

-- DIAGNOSTICS
vim.keymap.set('n', '<leader>dh', vim.diagnostic.open_float) -- diagnostic hover
vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setqflist)

-- WINDOWS
vim.keymap.set('n', '<c-o>', '<cmd>only<cr>')
-- Navigate windows by direction
vim.keymap.set('n', '<c-j>', '<cmd>wincmd j<cr>')
vim.keymap.set('n', '<c-k>', '<cmd>wincmd k<cr>')
vim.keymap.set('n', '<c-h>', '<cmd>wincmd h<cr>')
vim.keymap.set('n', '<c-l>', '<cmd>wincmd l<cr>')
vim.keymap.set('n', '<c-q>', '<cmd>wincmd q<cr>')
vim.keymap.set('n', '<c-x>', '<cmd>split %<cr>')

-- TABS
-- Open new tab with clone of current buffer
vim.keymap.set('n', '<c-t>', function() vim.cmd "tab split" end)
vim.keymap.set('n', '<leader>1', '<cmd>tabnext 1<cr>')
vim.keymap.set('n', '<leader>2', '<cmd>tabnext 2<cr>')
vim.keymap.set('n', '<leader>3', '<cmd>tabnext 3<cr>')
vim.keymap.set('n', '<leader>4', '<cmd>tabnext 4<cr>')
vim.keymap.set('n', '<leader>5', '<cmd>tabnext 5<cr>')
vim.keymap.set('n', '<leader>6', '<cmd>tabnext 6<cr>')
vim.keymap.set('n', '<leader>7', '<cmd>tabnext 7<cr>')
vim.keymap.set('n', '<leader>8', '<cmd>tabnext 8<cr>')
vim.keymap.set('n', '<leader>9', '<cmd>tabnext 9<cr>')

-- SCROLLING
-- Moves cursor 10 lines down or up
vim.keymap.set('n', 'J', '10j') -- I can still join lines in visual mode
vim.keymap.set('n', 'K', '10k')
-- move through wrapped lines visually
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('x', 'j', 'gj')
vim.keymap.set('x', 'k', 'gk')

-- Make carriage return do nothing
vim.keymap.set('n', '<cr>', '<nop>')
-- Avoid ex mode
vim.keymap.set('n', 'Q', '<nop>')

-- SELECTIONS
-- Text manipulation
vim.keymap.set('x', '<c-k>', ':move \'<-2<CR>gv-gv')
vim.keymap.set('x', '<c-j>', ':move \'>+1<CR>gv-gv')
-- Keeps selection active when indenting so you can do it multiple times quickly
vim.keymap.set('x', '>', '>gv')
vim.keymap.set('x', '<', '<gv')

-- MARKS
vim.keymap.set('n', '<c-m>', '<cmd>delmarks A-Z0-9<cr>') -- delete all marks

-- OTHER STUFF
-- Copy relative path of file
vim.keymap.set('n', 'f', '<cmd>let @+=expand("%")<cr><cmd>echo expand("%")<cr>')
-- Copy absolute path of file
vim.keymap.set('n', 'F', '<cmd>let @+=expand("%:p")<cr><cmd>echo expand("%:p")<cr>')
-- Make terminal mode easy to exit
vim.keymap.set('t', '<c-\\>', '<c-\\><c-n>')
-- Toggle spell
vim.keymap.set('n', '<c-s>', '<cmd>set spell!<cr>')
vim.keymap.set('n', '<c-p>', ToggleParedit)
vim.keymap.set('n', '<c-n>', '<cmd>set relativenumber!<cr>')

---------------------------------------------------------------------------------
-- AUTOCMDS

local general = vim.api.nvim_create_augroup('general', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'age',
  group = general,
  command = 'setlocal noendofline nofixendofline',
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = general,
  command = 'setlocal wrap',
})

-- Check file modification timestamp for writes from another source
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = '*',
  group = general,
  command = 'checktime',
})

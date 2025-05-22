-----------------------------------------------------------------------------
-- FUNCTIONS

vim.api.nvim_create_user_command('ToggleParedit',
  function()
    if vim.g.paredit_mode == 0 then
      vim.g.paredit_mode = 1
      print("paredit on")
    else
      vim.g.paredit_mode = 0
      print("paredit off")
    end
    -- Sometimes paredit seems to not get turned back on, this is a workaround
    vim.cmd 'edit'
  end,
  {
    desc = "Toggle paredit mode",
    force = false,
  }
)

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

----------------------------------------------------------------------------------------
-- GLOBALS

vim.g.mapleader = ' '
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
vim.diagnostic.config({
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN]  = "",
      [vim.diagnostic.severity.HINT]  = "󰟃",
      [vim.diagnostic.severity.INFO]  = "",
    },
  }
})
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
vim.keymap.set('n', 'J', '<c-d>') -- I can still join lines in visual mode
vim.keymap.set('n', 'K', '<c-u>')
-- Make carriage return do nothing
vim.keymap.set('n', '<cr>', '<nop>')
-- Avoid ex mode
vim.keymap.set('n', 'Q', '<nop>')

-- MARKS
vim.keymap.set('n', '<c-m>', '<cmd>delmarks A-Z0-9<cr>') -- delete all marks

-- OTHER STUFF
-- Copy absolute path of file
vim.keymap.set('n', '<leader>F', '<cmd>let @+=expand("%:p")<cr><cmd>echo expand("%:p")<cr>')
-- Make terminal mode easy to exit
vim.keymap.set('t', '<c-\\>', '<c-\\><c-n>')
vim.keymap.set('i', '<Tab>', function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })

---------------------------------------------------------------------------------
-- AUTOCMDS

local general = vim.api.nvim_create_augroup('general', { clear = true })

-- Disable expandtab for these filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'go' },
  group = general,
  command = 'set noexpandtab',
})

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

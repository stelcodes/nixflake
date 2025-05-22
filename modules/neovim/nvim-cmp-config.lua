local cmp = require 'cmp'
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'

lspkind.init {
  symbol_map = {
  },
}

vim.opt.completeopt = {           -- Completion behavior
  "menu",
  "menuone",
  "popup",
  "noselect",
  "preview",
  "fuzzy"
}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-j>'] = cmp.mapping.scroll_docs(3),
    ['<C-k>'] = cmp.mapping.scroll_docs(-3),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' }, -- For luasnip users.
  }, {
    { name = 'buffer' },
  }),
  formatting = {
    format = lspkind.cmp_format {
      with_text = true,
      menu = {
        buffer = "[buf]",
        nvim_lsp = "[LSP]",
        nvim_lua = "[api]",
        path = "[path]",
        luasnip = "[snip]",
      },
    },
  },
  experimental = {
    native_menu = false,
    -- ghost_text = false,
  },
}

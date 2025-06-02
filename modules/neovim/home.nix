{
  pkgs,
  lib,
  config,
  ...
}:
let
  theme = config.theme.set;
  plugins = pkgs.vimPlugins;
in
{
  xdg.configFile."nvim/data/telescope-sources" = {
    source = "${plugins.telescope-symbols-nvim}/data/telescope-sources";
    recursive = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = false;
    withNodeJs = false;
    withRuby = false;
    extraLuaConfig = builtins.readFile ./base.lua;
    extraPackages = lib.lists.optionals config.activities.coding [
      pkgs.clojure-lsp
      pkgs.nil
      pkgs.nixpkgs-fmt
      pkgs.ruff
      pkgs.pyright
      pkgs.typescript-language-server
      pkgs.rust-analyzer
      pkgs.java-language-server
      pkgs.lua-language-server
      pkgs.vscode-langservers-extracted
      pkgs.astro-language-server
      pkgs.gopls
      pkgs.svelte-language-server
      pkgs.tailwindcss-language-server
      pkgs.markdown-oxide
      pkgs.marksman
    ];
    plugins =
      let
        stel-paredit = pkgs.vimUtils.buildVimPlugin {
          pname = "stel-paredit";
          version = "1.0";
          src = pkgs.fetchFromGitHub {
            owner = "stelcodes";
            repo = "paredit";
            rev = "27d2ea61ac6117e9ba827bfccfbd14296c889c37";
            sha256 = "1bj5m1b4n2nnzvwbz0dhzg1alha2chbbdhfhl6rcngiprbdv0xi6";
          };
        };
        telekasten-calendar = pkgs.vimUtils.buildVimPlugin {
          pname = "telekasten-calendar";
          version = "unstable-2021-11-27";
          src = pkgs.fetchFromGitHub {
            owner = "nvim-telekasten";
            repo = "calendar-vim";
            rev = "a7e73e02c92566bf427b2a1d6a61a8f23542cc21";
            sha256 = "sha256-4XeDd+myM+wtHUsr3s1H9+GAwIjK8fAqBbFnBCeatPo=";
          };
        };
      in
      [

        {
          plugin = plugins.gitsigns-nvim;
          type = "lua";
          config = # lua
            ''
              local gs = require('gitsigns')
              gs.setup({
                signcolumn = false,
                numhl = true,
              })
              -- git reset
              vim.keymap.set('n', '<leader>gr', gs.reset_hunk)
              vim.keymap.set('v', '<leader>gr', function() gs.reset_hunk {vim.fn.line("."), vim.fn.line("v")} end)
              vim.keymap.set('n', '<leader>gR', gs.reset_buffer)
              -- git blame
              vim.keymap.set('n', '<leader>gb', function() gs.blame_line{full=true} end)
              vim.keymap.set('n', '<leader>gB', gs.blame)
              -- navigating and viewing hunks
              vim.keymap.set('n', '<leader>gn', gs.next_hunk)
              vim.keymap.set('n', ']g', gs.next_hunk)
              vim.keymap.set('n', '<leader>gp', gs.prev_hunk)
              vim.keymap.set('n', '[g', gs.prev_hunk)
              vim.keymap.set('n', '<leader>gp', gs.prev_hunk)
              vim.keymap.set('n', '<leader>gh', gs.preview_hunk)
            '';
        }

        {
          plugin = plugins.diffview-nvim;
          type = "lua";
          config = # lua
            ''
              -- https://github.com/sindrets/diffview.nvim/tree/main?tab=readme-ov-file#configuration
              local diff = require("diffview")
              local common_keymaps = {
                {"n", "<c-q>", '<cmd>DiffviewClose<cr>', { desc = "Close diffview" }}
              }
              diff.setup({
                enhanced_diff_hl = true,
                file_panel = {
                  listing_style = "list",
                  win_config = {
                    position = "bottom",
                    height = 10,
                  },
                },
                file_history_panel = {
                  win_config = {
                    position = "bottom",
                    height = 10,
                  },
                },
                keymaps = {
                  disable_defaults = false,
                  -- When only diff is visible (:DiffviewOpen or :DiffviewFileHistory)
                  view = common_keymaps,
                  -- When file panel is visible (:DiffviewOpen)
                  file_panel = common_keymaps,
                  -- When git log is open (:DiffviewFileHistory)
                  file_history_panel = common_keymaps,
                },
              })
              -- git diff
              vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>')
              -- git log
              vim.keymap.set('n', '<leader>gl', '<cmd>DiffviewFileHistory %<cr>')
              vim.keymap.set('n', '<leader>gL', '<cmd>DiffviewFileHistory<cr>')
            '';
        }

        {
          plugin = plugins.neogit;
          type = "lua";
          config = # lua
            ''
              local neogit = require('neogit')
              neogit.setup({
                -- disable_insert_on_commit = true,
                graph_style = "kitty",
                mappings = {
                  status = {
                    ["K"] = false; -- Don't override my normal K mapping
                  },
                },
              })

              -- https://github.com/NeogitOrg/neogit/issues/1682
              vim.api.nvim_create_autocmd({ "BufEnter" }, {
                pattern = "NeogitStatus",
                callback = function()
                  neogit.dispatch_refresh()
                end,
                group = neogit.autocmd_group,
              })

              local toggle_neogit = function()
                if vim.bo.filetype == "NeogitStatus" then
                  vim.cmd "bd"
                else
                  neogit.open()
                end
              end
              -- vim.keymap.set('n', '<c-g>', toggle_neogit)
            '';
        }

        # TODO: Remove this eventually, just keeping in case I miss fugitive
        {
          plugin = plugins.vim-fugitive;
          type = "lua";
          config = # lua
            ''
              local toggle_fugitive = function()
                if vim.bo.filetype == "fugitive" then
                  vim.cmd "wincmd q"
                else
                  vim.cmd "tabnew"
                  vim.cmd "Git"
                  vim.cmd "only"
                end
              end
              vim.keymap.set('n', '<c-g>', toggle_fugitive)
              -- vim.keymap.set('n', '<leader>gD', '<cmd>Git difftool<cr>')
            '';
        }

        {
          plugin = plugins.indent-blankline-nvim;
          type = "lua";
          config = # lua
            ''
              require("ibl").setup()
            '';
        }

        {
          plugin = plugins.nvim-autopairs;
          type = "lua";
          config = # lua
            ''
              require("nvim-autopairs").setup {}
            '';
        }

        {
          plugin = plugins.yazi-nvim;
          type = "lua";
          config = # lua
            ''
              local y = require('yazi')
              y.setup({
                open_for_directories = true,
              })
              vim.keymap.set('n', '<leader>y', function()
                vim.fn.setreg("/", "") -- clear search highlights
                y.yazi()
              end)
            '';
        }

        {
          plugin = plugins.grug-far-nvim;
          type = "lua";
          config = # lua
            ''
              local grug = require('grug-far')
              grug.setup({})
              -- vim.keymap.set('n', '<leader>r', grug.open)
              vim.api.nvim_create_user_command('SearchReplace', 'GrugFar', {})
            '';
        }

        # Theme plugin should go first because it sets local vars like lualine_theme
        theme.neovimPlugin

        {
          plugin = stel-paredit;
          type = "lua";
          config = # lua
            ''
              vim.g['paredit_smartjump'] = 1
              vim.g['paredit_matchlines'] = 500
            '';
        }

        {
          plugin = plugins.nvim-ts-autotag;
          type = "lua";
          config = # lua
            ''
              require("nvim-ts-autotag").setup {}
            '';
        }

        {
          # Required for telescope config
          plugin = plugins.trouble-nvim;
          type = "lua";
          config = # lua
            ''
              require('trouble').setup({
                focus = true,
              })
              -- vim.keymap.set('n', 'q', '<cmd>Trouble qflist<cr>')
            '';
        }
        plugins.plenary-nvim
        plugins.telescope-ui-select-nvim
        plugins.popup-nvim
        plugins.telescope-media-files-nvim
        plugins.telescope-fzf-native-nvim
        plugins.telescope-undo-nvim
        {
          plugin = plugins.telescope-nvim;
          type = "lua";
          config = builtins.readFile ./telescope-nvim-config.lua;
        }

        {
          plugin = pkgs.vimPlugins.nvim-bqf;
          type = "lua";
          config = # lua
            ''
              require('bqf').setup {
                auto_enable = true,
                auto_resize_height = true,
                preview = {
                  win_height = 20,
                  winblend = 0,
                },
              }
              vim.keymap.set('n', 'q', function()
                local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
                local action = qf_winid > 0 and 'cclose' or 'copen'
                vim.cmd(action)
              end)
            '';
        }

        {
          plugin = plugins.vim-auto-save;
          config = # vim
            "let g:auto_save = 1";
        }

        {
          plugin = plugins.lualine-nvim;
          type = "lua";
          config = # lua
            ''
              require('lualine').setup {
                options = {
                  theme = lualine_theme or 'auto',
                  component_separators = { left = "", right = ""},
                  section_separators = { left = "", right = ""},
                },
                sections = {
                  lualine_c = {'%f'},
                  lualine_x = {'filetype'},
                },
              }
            '';
        }

        plugins.nvim-web-devicons

        {
          plugin = plugins.bufferline-nvim;
          type = "lua";
          config = # lua
            ''
              local buff = require('bufferline')
              buff.setup {
                options = {
                  mode = 'buffers',
                  separator_style = 'thin',
                  sort_by = 'directory',
                  show_buffer_close_icons = false,
                  show_close_icon = false,
                  custom_filter = function(buf, buf_nums)
                    -- true if displayed, false if hidden
                    local banned_fts = { "help", "grug-far" }
                    for _, val in pairs(banned_fts) do
                      if vim.bo[buf].filetype == val then
                        return false
                      end
                    end
                    return true
                  end
                }
              }
              vim.api.nvim_set_hl(0, "BufferlineFill", { link = "BufferlineBackground" })
              vim.keymap.set('n', 'H', '<cmd>BufferLineCyclePrev<cr>')
              vim.keymap.set('n', 'L', '<cmd>BufferLineCycleNext<cr>')
            '';
        }

        plugins.vim-suda

        {
          plugin = plugins.nvim-colorizer-lua;
          type = "lua";
          config = # lua
            ''
              require 'colorizer'.setup {
                user_default_options = {
                  RGB = true, -- #RGB hex codes
                  RRGGBB = true, -- #RRGGBB hex codes
                  names = false, -- "Name" codes like Blue or blue
                  RRGGBBAA = true, -- #RRGGBBAA hex codes
                  AARRGGBB = true, -- 0xAARRGGBB hex codes
                  rgb_fn = true, -- CSS rgb() and rgba() functions
                  hsl_fn = true, -- CSS hsl() and hsla() functions
                  -- Available modes for `mode`: foreground, background,  virtualtext
                  mode = "virtualtext", -- Set the display mode.
                  -- Available methods are false / true / "normal" / "lsp" / "both"
                  -- True is same as normal
                  tailwind = "lsp", -- Enable tailwind colors
                  -- parsers can contain values used in |user_default_options|
                  sass = { enable = false, parsers = { "css" }, }, -- Enable sass colors
                  virtualtext = "■",
                },
              }
            '';
        }

        plugins.nvim-hlslens

        {
          plugin = plugins.nvim-notify;
          type = "lua";
          config = # lua
            ''
              vim.notify = require("notify")
            '';
        }

        telekasten-calendar
        {
          plugin = plugins.telekasten-nvim;
          type = "lua";
          config = # lua
            ''
              local notebox = vim.fn.expand("~/sync/notebox")
              require('telekasten').setup({
                home = notebox,
                templates = notebox.."/.templates",
                template_new_note = notebox.."/.templates/default.md",
                template_new_daily = notebox.."/.templates/daily.md",
                template_new_weekly = notebox.."/.templates/weekly.md",
              })
              vim.api.nvim_create_autocmd('FileType', {
                pattern = 'calendar',
                command = 'setlocal sidescrolloff=0',
              })
              vim.keymap.set("n", "<leader>np", "<cmd>Telekasten panel<CR>")
              vim.keymap.set("n", "<leader>nf", "<cmd>Telekasten find_notes<CR>")
              vim.keymap.set("n", "<leader>ns", "<cmd>Telekasten search_notes<CR>")
              vim.keymap.set("n", "<leader>nd", "<cmd>Telekasten goto_today<CR>")
              vim.keymap.set("n", "<leader>nw", "<cmd>Telekasten goto_thisweek<CR>")
              vim.keymap.set("n", "<leader>nl", "<cmd>Telekasten insert_link<CR>")
              vim.keymap.set("n", "<leader>nL", "<cmd>Telekasten insert_img_link<CR>")
              vim.keymap.set("n", "<leader>ng", "<cmd>Telekasten follow_link<CR>")
              vim.keymap.set("n", "<leader>nn", "<cmd>Telekasten new_note<CR>")
              vim.keymap.set("n", "<leader>nc", "<cmd>Telekasten show_calendar<CR>")
              vim.keymap.set("n", "<leader>nb", "<cmd>Telekasten show_backlinks<CR>")
              vim.keymap.set("n", "<leader>nr", "<cmd>Telekasten rename_note<CR>")
              vim.keymap.set("n", "<leader>nt", "<cmd>Telekasten show_tags<CR>")
              vim.keymap.set("n", "<leader>nx", "<cmd>Telekasten toggle_todo<CR>")
            '';
        }

        {
          plugin = plugins.mini-nvim;
          type = "lua";
          config = # lua
            ''
              require('mini.basics').setup({
                options = {
                  extra_ui = true,
                  win_borders = 'single',
                },
                mappings = {
                  windows = true,
                },
                autocommands = {
                  relnum_in_visual_mode = true,
                },
              })
              vim.opt.swapfile = false          -- turn swapfiles off
              vim.opt.scrolloff = 10            -- keep cursor centered vertically while scrolling
              vim.opt.sidescrolloff = 20        -- How many columns between cursor and edge when scrolling starts horizontally
              vim.opt.tabstop = 4               -- Show # spaces to represent a tab
              vim.opt.expandtab = true          -- Insert spaces instead of tabs on tab key
              vim.opt.shiftwidth = 2            -- Insert # spaces for tab key
              vim.opt.updatetime = 300          -- Faster completion
              vim.opt.timeout = false           -- Wait indefinitely for keymap continuation
              vim.opt.clipboard = 'unnamedplus' -- Copy paste between vim and everything else
              vim.opt.numberwidth = 1           -- Make minimum width for number column smallest value so it doesn't take up much room
              vim.opt.winblend = 0              -- Remove winblend floating transparency
              vim.opt.whichwrap = 'h,l'         -- Allow left/right scrolling to jump lines
              require('mini.comment').setup()
              -- require('mini.pairs').setup()
              require('mini.trailspace').setup()
              vim.api.nvim_create_user_command('Trim', 'lua MiniTrailspace.trim()', {})
              require('mini.move').setup({
                mappings = {
                  -- Move visual selection in Visual mode
                  left = '<c-h>',
                  right = '<c-l>',
                  down = '<c-j>',
                  up = '<c-k>',
                  -- Disable moving current line in Normal mode
                  line_left = "",
                  line_right = "",
                  line_down = "",
                  line_up = "",
                },
              })
               -- Fallback, keeps selection active when indenting
              vim.keymap.set('x', '>', '>gv')
              vim.keymap.set('x', '<', '<gv')
              require('mini.bracketed').setup()
              require('mini.bufremove').setup()
              require('mini.surround').setup()
              require('mini.sessions').setup({
                -- Once session has been created, automatically read and write to it
                autoread = true,
                autowrite = true,
                force = { read = false, write = true, delete = true },
              })
              vim.api.nvim_create_user_command('SessionCreate', 'mksession', {})
              vim.api.nvim_create_user_command('SessionDelete', 'lua MiniSessions.delete()', {})
            '';
        }

      ]
      ++ (lib.lists.optionals config.activities.coding [

        {
          plugin = plugins.nvim-treesitter.withAllGrammars;
          type = "lua";
          config = # lua
            ''
              require'nvim-treesitter.configs'.setup {
                -- ensure_installed = "all",
                highlight = {
                  enable = true,
                },
                indent = {
                  enable = true,
                }
              }
              vim.opt.foldlevel = 99
              vim.opt.foldenable = false -- toggle with zi
              vim.opt.foldmethod = 'expr'
              vim.cmd 'set foldexpr=nvim_treesitter#foldexpr()'
              -- This will work in future Neovim versions
              -- https://www.reddit.com/r/neovim/comments/16xz3q9/treesitter_highlighted_folds_are_now_in_neovim
              -- vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
              -- vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"

              -- Also Nix code will soon have support for embedded language injections with comments
              -- https://github.com/nvim-treesitter/nvim-treesitter/pull/4658
              -- Need version 2023-10-01 or later
            '';
        }

        {
          plugin = plugins.nvim-lspconfig;
          type = "lua";
          config = builtins.readFile ./nvim-lspconfig.lua;
        }

        {
          plugin = plugins.markdown-preview-nvim;
          config = # vim
            ''
              let g:mkdp_auto_close = 0
              let g:mkdp_echo_preview_url = 1
              let g:mkdp_browser = '${lib.getExe pkgs.open-browser-app}'
              let g:mkdp_theme = 'light'
            '';
        }

        {
          plugin = plugins.nvim-scrollbar;
          type = "lua";
          config = # lua
            ''
              require("scrollbar").setup({
                show_in_active_only = true,
                excluded_filetypes = {
                  "dropbar_menu",
                  "dropbar_menu_fzf",
                  "DressingInput",
                  "cmp_docs",
                  "cmp_menu",
                  "noice",
                  "prompt",
                  "TelescopePrompt",
                  "gitsigns-blame"
                },
              })
              -- requires nvim-hlslens, gitsigns
              require("scrollbar.handlers.search").setup()
              require("scrollbar.handlers.gitsigns").setup()
            '';
        }

        {
          plugin = plugins.nvim-cmp;
          type = "lua";
          config = builtins.readFile ./nvim-cmp-config.lua;
        }
        plugins.lspkind-nvim
        plugins.luasnip
        plugins.cmp-nvim-lua
        plugins.cmp-nvim-lsp

        plugins.playground

        {
          plugin = plugins.conjure;
          type = "lua";
          config = # lua
            ''
              vim.g['conjure#mapping#prefix'] = ','
              vim.g['conjure#log#hud#width'] = 1
              vim.g['conjure#log#hud#height'] = 0.6
              vim.g['conjure#client#clojure#nrepl#connection#auto_repl#enabled'] = false
              vim.g['conjure#eval#gsubs'] = {
                ['do-comment'] = {'^%(comment[%s%c]', '(do '}
              }
              vim.g['conjure#eval#result_register'] = '*'
              vim.g['conjure#mapping#doc_word'] = '<localleader>K'
              vim.g['conjure#client_on_load'] = false
            '';
        }

      ]);
  };
}

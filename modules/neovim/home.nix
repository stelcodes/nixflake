{ pkgs, lib, config, inputs, ... }:
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
        resize-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "resize-nvim";
          version = "unstable-2024-01-16";
          src = pkgs.fetchFromGitHub {
            owner = "stelcodes";
            repo = "resize.nvim";
            rev = "a0b28847f69d234de933685503df84a88e7ae514";
            sha256 = "jGEVE9gfK4EirGDOFzSNXn60X+IldKASVoTD4/p7MBM=";
          };
        };
        workspace-diagnostics-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "workspace-diagnostics-nvim";
          version = "unstable";
          src = inputs.workspace-diagnostics-nvim;
        };

      in
      [

        {
          plugin = plugins.gitsigns-nvim;
          type = "lua";
          config = /* lua */ ''
            local gs = require('gitsigns')
            gs.setup()
            -- git reset
            vim.keymap.set('n', '<leader>gr', gs.reset_hunk)
            vim.keymap.set('v', '<leader>gr', function() gs.reset_hunk {vim.fn.line("."), vim.fn.line("v")} end)
            vim.keymap.set('n', '<leader>gR', gs.reset_buffer)
            -- git blame
            vim.keymap.set('n', '<leader>gb', function() gs.blame_line{full=true} end)
            vim.keymap.set('n', '<leader>gB', gs.toggle_current_line_blame)
            -- navigating and viewing hunks
            vim.keymap.set('n', '<leader>gn', gs.next_hunk)
            vim.keymap.set('n', '<leader>gp', gs.prev_hunk)
            vim.keymap.set('n', '<leader>gh', gs.preview_hunk)
          '';
        }

        {
          plugin = plugins.diffview-nvim;
          type = "lua";
          config = /* lua */ ''
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
          config = /* lua */ ''
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

        {
          plugin = plugins.indent-blankline-nvim;
          type = "lua";
          config = /* lua */ ''
            require("ibl").setup()
          '';
        }

        # TODO: Remove this eventually, just keeping in case I miss fugitive
        {
          plugin = plugins.vim-fugitive;
          type = "lua";
          config = /* lua */ ''
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
          plugin = plugins.yazi-nvim;
          type = "lua";
          config = /* lua */ ''
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
          config = /* lua */ ''
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
          config = /* lua */ ''
            vim.g['paredit_smartjump'] = 1
            vim.g['paredit_matchlines'] = 500
          '';
        }

        {
          plugin = plugins.nvim-autopairs;
          type = "lua";
          config = /* lua */ ''
            require("nvim-autopairs").setup {}
          '';
        }

        {
          plugin = plugins.nvim-ts-autotag;
          type = "lua";
          config = /* lua */ ''
            require("nvim-ts-autotag").setup {}
          '';
        }

        {
          # Required for telescope config
          plugin = plugins.trouble-nvim;
          type = "lua";
          config = /* lua */ ''
            require('trouble').setup({
              focus = true,
            })
            vim.keymap.set('n', 'q', '<cmd>Trouble qflist<cr>')
          '';
        }
        plugins.plenary-nvim
        plugins.telescope-file-browser-nvim
        plugins.telescope-ui-select-nvim
        plugins.telescope-fzf-native-nvim
        plugins.telescope-manix
        {
          plugin = plugins.telescope-nvim;
          type = "lua";
          config = builtins.readFile ./telescope-nvim-config.lua;
        }

        {
          plugin = plugins.vim-auto-save;
          config = /* vim */ "let g:auto_save = 1";
        }

        {
          plugin = plugins.comment-nvim;
          type = "lua";
          config = /* lua */ ''
            local opts = {}
            -- Don't rely on this plugin or treesitter being present
            local success, pre_hook = pcall(function()
              require('ts_context_commentstring').setup {
                enable_autocmd = false,
              }
              return require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
            end)
            if success then
              opts.pre_hook = pre_hook
            end
            require('Comment').setup(opts)
            local ft = require('Comment.ft')
            ft.set('clojure', ';; %s')
          '';
        }

        {
          plugin = plugins.lualine-nvim;
          type = "lua";
          config = /* lua */ ''
            require('lualine').setup {
              options = {
                icons_enabled = true,
                theme = lualine_theme or 'auto',
                component_separators = { left = "", right = ""},
                section_separators = { left = "", right = ""},
                disabled_filetypes = {},
                always_divide_middle = true,
              },
              sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {'%f'},
                lualine_x = {'filetype'},
                lualine_y = {'progress'},
                lualine_z = {'location'}
              },
              inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {'filename'},
                lualine_x = {'location'},
                lualine_y = {},
                lualine_z = {}
              },
              tabline = {},
              -- extensions = {'nvim-tree'}
            }
          '';
        }

        {
          plugin = plugins.auto-session;
          type = "lua";
          config = /* lua */ ''
            vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
            require('auto-session').setup {
              auto_save_enabled = true,
              auto_restore_enabled = true
            }
          '';
        }

        plugins.nvim-web-devicons

        {
          plugin = plugins.bufferline-nvim;
          type = "lua";
          config = /* lua */ ''
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
          config = /* lua */ ''
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
                tailwind = false, -- Enable tailwind colors
                -- parsers can contain values used in |user_default_options|
                sass = { enable = false, parsers = { "css" }, }, -- Enable sass colors
                virtualtext = "■",
              },
            }
          '';
        }

        {
          plugin = plugins.vim-better-whitespace;
          type = "lua";
          config = /* lua */ ''
            vim.g["better_whitespace_guicolor"] = "${theme.red}"
            vim.g["better_whitespace_filetypes_blacklist"] = {
              "diff", "git", "gitcommit", "unite", "qf", "help", "fugitive"
            }
          '';
        }

        plugins.vim-just

        {
          plugin = resize-nvim;
          type = "lua";
          config = /* lua */ ''
            local r = require('resize')
            vim.keymap.set('n', '<s-left>', function() r.ResizeLeft(1) end)
            vim.keymap.set('n', '<s-right>', function() r.ResizeRight(1) end)
            vim.keymap.set('n', '<s-up>', function() r.ResizeUp(1) end)
            vim.keymap.set('n', '<s-down>', function() r.ResizeDown(1) end)
          '';
        }

        {
          plugin = pkgs.vimUtils.buildVimPlugin {
            pname = "nvim-listchars";
            version = "unstable-2024-02-24";
            src = pkgs.fetchFromGitHub {
              owner = "0xfraso";
              repo = "nvim-listchars";
              rev = "40b05e8375af11253434376154a9e6b3e9400747";
              hash = "sha256-SQPe1c3EzVdqpU41FqwR2owfstDqSLjNlrpJuaLZXNE=";
            };
          };
          type = "lua";
          config = /* lua */ ''
            vim.opt.list = true
            require("nvim-listchars").setup {
              save_state = true,
              notifications = false,
              listchars = {
                -- space = ' ',
                eol = "↲",
                tab = "» ",
                trail = '·',
                extends = '<',
                precedes = '>',
                conceal = '┊',
                nbsp = '␣',
              },
            }
            vim.cmd 'ListcharsDarkenColors'
            vim.keymap.set('n', '<c-.>', '<cmd>ListcharsToggle<cr>')
          '';
        }

      ] ++ (lib.lists.optionals config.activities.coding [

        workspace-diagnostics-nvim

        plugins.nvim-ts-context-commentstring # For accurate comments
        {
          plugin = plugins.nvim-treesitter.withAllGrammars;
          type = "lua";
          config = /* lua */ ''
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

        plugins.markdown-preview-nvim

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
          config = /* lua */ ''
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

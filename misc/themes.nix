{ pkgs, ... }:
{

  # https://github.com/tinted-theming/base16-schemes
  # https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  # s/\v(\w+): "(\w+)"/\1 = "#\2";

  nord = rec {
    name = "nord";

    base00 = "#2E3440";
    base01 = "#3B4252";
    base02 = "#434C5E";
    base03 = "#4C566A";
    base04 = "#D8DEE9";
    base05 = "#E5E9F0";
    base06 = "#ECEFF4";
    base07 = "#8FBCBB";
    base08 = "#BF616A";
    base09 = "#D08770";
    base0A = "#EBCB8B";
    base0B = "#A3BE8C";
    base0C = "#88C0D0";
    base0D = "#81A1C1";
    base0E = "#B48EAD";
    base0F = "#5E81AC";

    bg = base00;
    bg1 = base01;
    bg2 = base02;
    bg3 = base03;
    bg4 = base04;
    fg = base05;
    fg1 = base06;
    alt1 = base07;
    red = base08;
    orange = base09;
    yellow = base0A;
    green = base0B;
    cyan = base0C;
    blue = base0D;
    magenta = base0E;
    alt2 = base0F;

    bgx = builtins.substring 1 6 bg;
    bg1x = builtins.substring 1 6 bg1;
    bg2x = builtins.substring 1 6 bg2;
    bg3x = builtins.substring 1 6 bg3;
    bg4x = builtins.substring 1 6 bg4;
    fgx = builtins.substring 1 6 fg;
    fg1x = builtins.substring 1 6 fg1;
    alt1x = builtins.substring 1 6 alt1;
    redx = builtins.substring 1 6 red;
    orangex = builtins.substring 1 6 orange;
    yellowx = builtins.substring 1 6 yellow;
    greenx = builtins.substring 1 6 green;
    cyanx = builtins.substring 1 6 cyan;
    bluex = builtins.substring 1 6 blue;
    magentax = builtins.substring 1 6 magenta;
    alt2x = builtins.substring 1 6 alt2;

    black = "#222730";
    # swayBorder = "#616e88";

    gtkThemeName = "Nordic";
    gtkThemePackage = pkgs.nordic;
    iconThemeName = "Nordzy";
    iconThemePackage = pkgs.nordzy-icon-theme;
    cursorThemeName = "Nordzy-cursors";
    cursorThemePackage = pkgs.nordzy-cursor-theme;

    neovimPlugin = {
      plugin = pkgs.vimPlugins.nordic-nvim;
      type = "lua";
      config = ''
        require('nordic').colorscheme {
          underline_option = 'none',
          italic = false,
          italic_comments = false,
          minimal_mode = true,
          alternate_backgrounds = false
        }
        vim.cmd 'colorscheme nordic'

        -- switch lualine nord theme normal bg colors
        local lualine_theme = require('lualine.themes.nord')
        local tmp = lualine_theme.normal.b.bg
        lualine_theme.normal.b.bg = lualine_theme.normal.c.bg
        lualine_theme.normal.c.bg = tmp
      '';
    };

    markdownPreviewCSS = builtins.readFile ./markdown-preview-nvim-nord-theme.css;

    tmuxPrimary = cyan;
    tmuxSecondary = yellow;

    vscode = {
      extension = pkgs.vscode-extensions.arcticicestudio.nord-visual-studio-code;
      themeName = "Nord";
    };

    btop = "nord";
  };

  everforest = rec {
    name = "everforest";

    base00 = "#333c43";
    # original base00 = "#2f383e";
    base01 = "#374247";
    # original base01 = "#374247";
    base02 = "#414b50";
    # original base02 = "#4a555b";
    base03 = "#859289";
    base04 = "#9da9a0";
    base05 = "#d3c6aa";
    base06 = "#e4e1cd";
    base07 = "#fdf6e3";
    base08 = "#7fbbb3";
    base09 = "#d699b6";
    base0A = "#dbbc7f";
    base0B = "#83c092";
    base0C = "#e69875";
    base0D = "#a7c080";
    base0E = "#e67e80";
    base0F = "#eaedc8";

    bg = base00;
    bg1 = base01;
    bg2 = base02;
    bg3 = base03;
    bg4 = base04;
    fg = base05;
    fg1 = base06;
    alt1 = base07;
    red = base0E;
    orange = base0C;
    yellow = base0A;
    green = base0D;
    cyan = base0B;
    blue = base08;
    magenta = base09;
    alt2 = base0F;

    bgx = builtins.substring 1 6 bg;
    bg1x = builtins.substring 1 6 bg1;
    bg2x = builtins.substring 1 6 bg2;
    bg3x = builtins.substring 1 6 bg3;
    bg4x = builtins.substring 1 6 bg4;
    fgx = builtins.substring 1 6 fg;
    fg1x = builtins.substring 1 6 fg1;
    alt1x = builtins.substring 1 6 alt1;
    redx = builtins.substring 1 6 red;
    orangex = builtins.substring 1 6 orange;
    yellowx = builtins.substring 1 6 yellow;
    greenx = builtins.substring 1 6 green;
    cyanx = builtins.substring 1 6 cyan;
    bluex = builtins.substring 1 6 blue;
    magentax = builtins.substring 1 6 magenta;
    alt2x = builtins.substring 1 6 alt2;

    black = "#15191c";

    gtkThemeName = "Everforest-Dark-Medium";
    gtkThemePackage = pkgs.everforest-gtk-theme.override {
      colorVariants = [ "dark" ];
      themeVariants = [ "default" ];
      sizeVariants = [ "standard" ];
      iconVariants = [ "dark" ];
      tweakVariants = [
        "outline"
        "medium"
      ];
    };
    iconThemeName = "Everforest-Dark";
    iconThemePackage = gtkThemePackage;
    cursorThemeName = "everforest-cursors";
    cursorThemePackage = pkgs.everforest-cursors;

    neovimPlugin = {
      plugin = pkgs.vimPlugins.everforest;
      type = "lua";
      config = ''
        vim.g["everforest_background"] = "soft"
        vim.g["everforest_better_performance"] = 0
        vim.cmd 'colorscheme everforest'
        local lualine_theme = require('lualine.themes.everforest')
      '';
    };

    tmuxPrimary = green;
    tmuxSecondary = red;

    btop = "everforest-dark-medium";

    wallpaper = builtins.toString (
      pkgs.fetchurl {
        url = "https://i.ibb.co/fDjcr2G/00016.jpg";
        hash = "sha256-ZWVIhfwoHlLdge/ECmdWfcZjbqWfc/aPfr+dBsx8/eE=";
      }
    );

    kittyThemeFile = "everforest_dark_soft";
  };

  catppuccin-frappe = rec {
    # https://github.com/catppuccin/catppuccin

    name = "catppuccin-frappe";

    # https://github.com/catppuccin/base16/tree/main/base16
    base00 = "#303446"; # base
    base01 = "#292c3c"; # mantle
    base02 = "#414559"; # surface0
    base03 = "#51576d"; # surface1
    base04 = "#626880"; # surface2
    base05 = "#c6d0f5"; # text
    base06 = "#f2d5cf"; # rosewater
    base07 = "#babbf1"; # lavender
    base08 = "#e78284"; # red
    base09 = "#ef9f76"; # peach
    base0A = "#e5c890"; # yellow
    base0B = "#a6d189"; # green
    base0C = "#81c8be"; # teal
    base0D = "#8caaee"; # blue
    base0E = "#ca9ee6"; # mauve
    base0F = "#eebebe"; # flamingo

    bg = base00;
    bg1 = base01;
    bg2 = base02;
    bg3 = base03;
    bg4 = base04;
    fg = base05;
    fg1 = base06;
    alt1 = base07;
    red = base08;
    orange = base09;
    yellow = base0A;
    green = base0B;
    cyan = base0C;
    blue = base0D;
    magenta = base0E;
    alt2 = base0F;

    bgx = builtins.substring 1 6 bg;
    bg1x = builtins.substring 1 6 bg1;
    bg2x = builtins.substring 1 6 bg2;
    bg3x = builtins.substring 1 6 bg3;
    bg4x = builtins.substring 1 6 bg4;
    fgx = builtins.substring 1 6 fg;
    fg1x = builtins.substring 1 6 fg1;
    alt1x = builtins.substring 1 6 alt1;
    redx = builtins.substring 1 6 red;
    orangex = builtins.substring 1 6 orange;
    yellowx = builtins.substring 1 6 yellow;
    greenx = builtins.substring 1 6 green;
    cyanx = builtins.substring 1 6 cyan;
    bluex = builtins.substring 1 6 blue;
    magentax = builtins.substring 1 6 magenta;
    alt2x = builtins.substring 1 6 alt2;

    black = "#15191c"; # weirdly needed but ok

    btop = "toyko-storm";

    tmuxPrimary = blue;
    tmuxSecondary = orange;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/themes/catppuccin-gtk/default.nix
    gtkThemeName = "Catppuccin-Frappe-Standard-Pink-Dark";
    gtkThemePackage = pkgs.catppuccin-gtk.override {
      variant = "frappe";
      accents = [ "pink" ]; # You can specify multiple accents here to output multiple themes
      size = "standard";
      tweaks = [ ]; # You can also specify multiple tweaks here
    };

    iconThemeName = "Catppuccin-Frappe";
    iconThemePackage = pkgs.callPackage ../packages/catppuccin-gtk-theme.nix { };
    cursorThemeName = "frappePink";
    cursorThemePackage = pkgs.catppuccin-cursors;

    neovimPlugin = {
      plugin = pkgs.vimPlugins.catppuccin-nvim;
      type = "lua";
      config = # lua
        ''
          require("catppuccin").setup({
            flavour = "frappe", -- latte, frappe, macchiato, mocha
            background = { -- :h background
                light = "latte",
                dark = "frappe",
            },
          })
          -- setup must be called before loading
          vim.cmd.colorscheme "catppuccin"
          local lualine_theme = require('lualine.themes.catppuccin')
        '';
    };

    configFile = {
      "gtk-4.0/assets".source = "${gtkThemePackage}/share/themes/${gtkThemeName}/gtk-4.0/assets";
      "gtk-4.0/gtk.css".source = "${gtkThemePackage}/share/themes/${gtkThemeName}/gtk-4.0/gtk.css";
      "gtk-4.0/gtk-dark.css".source =
        "${gtkThemePackage}/share/themes/${gtkThemeName}/gtk-4.0/gtk-dark.css";
    };
  };

  catppuccin-macchiato = rec {

    # https://github.com/catppuccin/catppuccin

    name = "catppuccin-macchiato";

    # https://github.com/catppuccin/base16/tree/main/base16
    base00 = "#24273a"; # base
    base01 = "#1e2030"; # mantle
    base02 = "#363a4f"; # surface0
    base03 = "#494d64"; # surface1
    base04 = "#5b6078"; # surface2
    base05 = "#cad3f5"; # text
    base06 = "#f4dbd6"; # rosewater
    base07 = "#b7bdf8"; # lavender
    base08 = "#ed8796"; # red
    base09 = "#f5a97f"; # peach
    base0A = "#eed49f"; # yellow
    base0B = "#a6da95"; # green
    base0C = "#8bd5ca"; # teal
    base0D = "#8aadf4"; # blue
    base0E = "#c6a0f6"; # mauve
    base0F = "#f0c6c6"; # flamingo

    bg = base00;
    bg1 = base01;
    bg2 = base02;
    bg3 = base03;
    bg4 = base04;
    fg = base05;
    fg1 = base06;
    alt1 = base07;
    red = base08;
    orange = base09;
    yellow = base0A;
    green = base0B;
    cyan = base0C;
    blue = base0D;
    magenta = base0E;
    alt2 = base0F;

    bgx = builtins.substring 1 6 bg;
    bg1x = builtins.substring 1 6 bg1;
    bg2x = builtins.substring 1 6 bg2;
    bg3x = builtins.substring 1 6 bg3;
    bg4x = builtins.substring 1 6 bg4;
    fgx = builtins.substring 1 6 fg;
    fg1x = builtins.substring 1 6 fg1;
    alt1x = builtins.substring 1 6 alt1;
    redx = builtins.substring 1 6 red;
    orangex = builtins.substring 1 6 orange;
    yellowx = builtins.substring 1 6 yellow;
    greenx = builtins.substring 1 6 green;
    cyanx = builtins.substring 1 6 cyan;
    bluex = builtins.substring 1 6 blue;
    magentax = builtins.substring 1 6 magenta;
    alt2x = builtins.substring 1 6 alt2;

    black = "#15191c"; # weirdly needed but ok

    btop = "catppuccin_macchiato";

    tmuxPrimary = blue;
    tmuxSecondary = orange;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/themes/catppuccin-gtk/default.nix
    gtkThemeName = "Catppuccin-Macchiato-Standard-Mauve-Dark";
    gtkThemePackage = (pkgs.callPackage ../packages/catppuccin-gtk { }).override {
      variant = "macchiato";
      accents = [ "mauve" ]; # You can specify multiple accents here to output multiple themes
      size = "standard";
      tweaks = [ ]; # You can also specify multiple tweaks here
    };
    gtkConfigFiles = {
      "gtk-4.0/assets".source = "${gtkThemePackage}/share/themes/${gtkThemeName}/gtk-4.0/assets";
      "gtk-4.0/gtk.css".source = "${gtkThemePackage}/share/themes/${gtkThemeName}/gtk-4.0/gtk.css";
      "gtk-4.0/gtk-dark.css".source =
        "${gtkThemePackage}/share/themes/${gtkThemeName}/gtk-4.0/gtk-dark.css";
    };

    iconThemeName = "Catppuccin-Macchiato";
    iconThemePackage = pkgs.callPackage ../packages/catppuccin-gtk-theme.nix { };
    cursorThemeName = "catppuccin-macchiato-pink-cursors";
    cursorThemePackage = pkgs.catppuccin-cursors.macchiatoPink;

    neovimPlugin = {
      plugin = pkgs.vimPlugins.catppuccin-nvim;
      type = "lua";
      config = # lua
        ''
          require("catppuccin").setup({
            flavour = "macchiato", -- latte, frappe, macchiato, mocha
          })
          -- setup must be called before loading
          vim.cmd.colorscheme "catppuccin"
          local lualine_theme = require('lualine.themes.catppuccin')
        '';
    };

    kittyThemeFile = "Catppuccin-Macchiato";
  };

  rose-pine = rec {

    name = "rose-pine";

    base00 = "#191724";
    base01 = "#1f1d2e";
    base02 = "#26233a";
    base03 = "#6e6a86";
    base04 = "#908caa";
    base05 = "#e0def4";
    base06 = "#e0def4";
    base07 = "#524f67";
    base08 = "#eb6f92";
    base09 = "#f6c177";
    base0A = "#ebbcba";
    base0B = "#31748f";
    base0C = "#9ccfd8";
    base0D = "#c4a7e7";
    base0E = "#f6c177";
    base0F = "#524f67";

    bg = base00;
    bg1 = base01;
    bg2 = base02;
    bg3 = base03;
    bg4 = base04;
    fg = base05;
    fg1 = base06;
    alt1 = base07;
    red = base08;
    yellow = base09;
    green = base0A;
    blue = base0B;
    cyan = base0C;
    magenta = base0D;
    orange = base0E;
    alt2 = base0F;

    bgx = builtins.substring 1 6 bg;
    bg1x = builtins.substring 1 6 bg1;
    bg2x = builtins.substring 1 6 bg2;
    bg3x = builtins.substring 1 6 bg3;
    bg4x = builtins.substring 1 6 bg4;
    fgx = builtins.substring 1 6 fg;
    fg1x = builtins.substring 1 6 fg1;
    alt1x = builtins.substring 1 6 alt1;
    redx = builtins.substring 1 6 red;
    orangex = builtins.substring 1 6 orange;
    yellowx = builtins.substring 1 6 yellow;
    greenx = builtins.substring 1 6 green;
    cyanx = builtins.substring 1 6 cyan;
    bluex = builtins.substring 1 6 blue;
    magentax = builtins.substring 1 6 magenta;
    alt2x = builtins.substring 1 6 alt2;

    black = "#222730";
    # swayBorder = "#616e88";

    gtkThemeName = "RosePine-Main-BL";
    gtkThemePackage = pkgs.callPackage ../packages/rose-pine-gtk-theme.nix { };
    iconThemeName = "Rose-Pine";
    iconThemePackage = gtkThemePackage;
    cursorThemeName = "Nordzy-cursors";
    cursorThemePackage = pkgs.nordzy-cursor-theme;

    neovimPlugin = {
      plugin = pkgs.vimPlugins.rose-pine;
      type = "lua";
      config = ''
        require('rose-pine').setup {
          variant = 'main',
        }
        vim.cmd 'colorscheme rose-pine'
        local lualine_theme = require('lualine.themes.rose-pine')
      '';
    };

    # markdownPreviewCSS = builtins.readFile ./markdown-preview-nvim-nord-theme.css;

    tmuxPrimary = green;
    tmuxSecondary = cyan;

    btop = "tokyo-storm";

  };
}

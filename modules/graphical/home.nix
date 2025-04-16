{ pkgs, config, inputs, lib, ... }:
let
  theme = config.theme.set;
in
{
  config = lib.mkIf config.profile.graphical {

    home = {
      packages = lib.mkIf pkgs.stdenv.isLinux [
        # pkgs.material-icons # for mpv uosc
        # pkgs.mpv-unify # custom mpv python wrapper
        pkgs.keepassxc
        pkgs.ungoogled-chromium
        pkgs.librewolf
        pkgs.vlc
      ];

      # Need to create aliases because Launchbar doesn't look through symlinks.
      # Enable Other in Spotlight to see Nix apps
      activation.link-apps = lib.mkIf pkgs.stdenv.isDarwin (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        new_nix_apps="${config.home.homeDirectory}/Applications/Nix"
        rm -rf "$new_nix_apps"
        mkdir -p "$new_nix_apps"
        find -H -L "$newGenPath/home-files/Applications" -name "*.app" -type d -print | while read -r app; do
          real_app=$(readlink -f "$app")
          app_name=$(basename "$app")
          target_app="$new_nix_apps/$app_name"
          echo "Alias '$real_app' to '$target_app'"
          ${pkgs.mkalias}/bin/mkalias "$real_app" "$target_app"
        done
      '');
      file = {
        # https://librewolf.net/docs/settings/
        ".librewolf/librewolf.overrides.cfg".text = /* js */ ''
          pref("browser.tabs.insertAfterCurrent", true);
          pref("browser.uidensity", 1);
          pref("browser.toolbars.bookmarks.visibility", "never")
        '';
      };
    };

    programs = {

      mpv = {
        enable = false;
        config = {
          # turn off default interface, use uosc instead
          osd-bar = "no";
          border = "no";
          sub-auto = "all";
          demuxer-max-bytes = "2048MiB";
          gapless-audio = "no";
        };
        scripts = let p = pkgs.mpvScripts; in [
          p.uosc
          p.thumbfast
          p.mpv-cheatsheet
          p.videoclip
        ] ++ lib.lists.optionals pkgs.stdenv.isLinux [
          p.mpris
        ];
        # scriptOpts = {
        #   videoclip = {
        #   };
        # };
      };

      kitty = {
        enable = true;
        # https://github.com/kovidgoyal/kitty-themes/tree/master/themes without .conf
        themeFile = theme.kittyThemeFile;
        font = {
          # Needs to be 12 on sway, at least on Framework laptop
          size = if pkgs.stdenv.isLinux then 12 else 16;
          name = "FiraMono Nerd Font";
          package = pkgs.nerd-fonts.fira-mono;
        };
        keybindings = {
          "ctrl+c" = "copy_to_clipboard";
          "ctrl+shift+c" = "send_key ctrl+c";
          "ctrl+v" = "paste_from_clipboard";
          "ctrl+shift+v" = "send_key ctrl+v";
          # Standard copy/paste keymaps for MacOS
          "super+c" = "copy_to_clipboard";
          "super+v" = "paste_from_clipboard";
          "kitty_mod+equal" = "change_font_size all 0";
          "kitty_mod+plus" = "change_font_size all +1.0";
          "kitty_mod+minus" = "change_font_size all -1.0";
        };
        settings = {
          disable_ligatures = "never";
          shell = "${pkgs.zsh}/bin/zsh";
          wheel_scroll_multiplier = "5.0";
          touch_scroll_multiplier = "1.0";
          copy_on_select = "yes";
          enable_audio_bell = "no";
          confirm_os_window_close = "1";
          macos_titlebar_color = "background";
          macos_option_as_alt = "left";
          macos_quit_when_last_window_closed = "yes";
          kitty_mod = "ctrl+alt";
          clear_all_shortcuts = "yes";
          wayland_titlebar_color = "background";
        };
      };

      gnome-shell = {
        theme = {
          name = theme.gtkThemeName;
          package = theme.gtkThemePackage;
        };
      };
    };

    dconf.settings =
      # dconf dump /org/cinnamon/ | dconf2nix | nvim -R
      # nix shell nixpkgs#dconf2nix nixpkgs#dconf-editor
      {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
        "org/gnome/desktop/wm/preferences" = {
          # button-layout = "appmenu:close"; # Only show close button
        };
        "org/gnome/desktop/wm/keybindings" = {
          minimize = [ "<Super>m" ];
          move-to-workspace-1 = [ "<Shift><Super>1" ];
          move-to-workspace-2 = [ "<Shift><Super>2" ];
          move-to-workspace-3 = [ "<Shift><Super>3" ];
          move-to-workspace-4 = [ "<Shift><Super>4" ];
          move-to-workspace-left = [ "<Shift><Super>h" ];
          move-to-workspace-right = [ "<Shift><Super>l" ];
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-to-workspace-left = [ "<Super>h" ];
          switch-to-workspace-right = [ "<Super>l" ];
        };
        "org/gnome/desktop/background" = {
          picture-uri = "file://${pkgs.wallpaper.anime-girl-coffee}";
          picture-uri-dark = "file://${pkgs.wallpaper.anime-girl-coffee}";
        };
      };

    qt = {
      # Necessary for keepassxc, qpwgrapgh, etc to theme correctly
      enable = true;
      platformTheme.name = "gtk";
      style.name = "gtk2";
    };

    gtk = {
      enable = true;
      font = {
        name = "FiraMono Nerd Font";
        size = 10;
      };
      theme = {
        name = theme.gtkThemeName;
        package = theme.gtkThemePackage;
      };
      iconTheme = {
        name = theme.iconThemeName;
        package = theme.iconThemePackage;
      };
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };


  };
}

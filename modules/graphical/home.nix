{
  pkgs,
  config,
  lib,
  ...
}:
let
  theme = config.theme.set;
in
{
  imports = [ ./graphical-linux.home.nix ];
  config = lib.mkIf config.profile.graphical {
    home = {
      # Need to create aliases because Launchbar doesn't look through symlinks.
      # Enable Other in Spotlight to see Nix apps
      activation.link-apps = lib.mkIf pkgs.stdenv.isDarwin (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
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
        ''
      );
      file = {
        # https://librewolf.net/docs/settings/
        # pref activates upon every librewolf startup but can be changed while running
        ".librewolf/librewolf.overrides.cfg".text = # js
          ''
            pref("browser.tabs.insertAfterCurrent", true);
            pref("browser.uidensity", 1);
            pref("browser.toolbars.bookmarks.visibility", "never")
            pref("browser.fullscreen.autohide", false)
            pref("privacy.clearOnShutdown.history", true);
            pref("privacy.clearOnShutdown.downloads", true);
            pref("browser.sessionstore.resume_from_crash", false);
            pref("webgl.disabled", true);
            pref("clipboard.autocopy", false);
            pref("middlemouse.paste", false);
            pref("browser.newtabpage.enabled", false);
            pref("browser.startup.homepage", "chrome:\/\/browser/content/blanktab.html");
          '';
      };
    };
    programs.kitty = {
      enable = true;
      # https://github.com/kovidgoyal/kitty-themes/tree/master/themes without .conf
      themeFile = theme.kittyThemeFile;
      font = {
        # Needs to be 12 on sway, at least on Framework laptop
        size = if pkgs.stdenv.isLinux then 12 else 16;
        name = "FiraMono Nerd Font";
        package = pkgs.nerd-fonts.fira-mono;
      };
      actionAliases = {
        new_tab_after = "launch --type=tab --cwd=current --location=after";
        new_window_after = "launch --type=window --cwd=current --location=after";
      };
      # man 5 kitty.conf
      settings = {
        scrollback_pager_history_size = "10"; # 10MB ~= 100000 lines
        scrollback_fill_enlarged_window = "yes";
        copy_on_select = "clipboard";
        enable_audio_bell = "no";
        confirm_os_window_close = "-1 count-background";
        enabled_layouts = "fat,tall,horizontal,vertical";
        tab_bar_style = "slant";
        tab_bar_min_tabs = "1";
        tab_title_max_length = "20";
        shell = "${pkgs.zsh}/bin/zsh";
        # allow_remote_control = "yes";
        # listen_on = "unix:${HOME}/.local/state/kittysock";
        notify_on_cmd_finish = "invisible";
        wayland_titlebar_color = "background";
        wayland_enable_ime = "no";
        macos_titlebar_color = "background";
        macos_option_as_alt = "left";
        macos_quit_when_last_window_closed = "yes";
        clear_all_shortcuts = "yes";
        kitty_mod = "alt";
      };
      keybindings = {
        "kitty_mod+ctrl+u" = "scroll_page_up";
        "kitty_mod+ctrl+d" = "scroll_page_down";
        "kitty_mod+[" = "scroll_to_prompt -1";
        "kitty_mod+]" = "scroll_to_prompt 1";
        "kitty_mod+space" = "show_scrollback";
        "kitty_mod+shift+space" = "show_first_command_output_on_screen";
        "kitty_mod+x" = "new_window_after";
        "kitty_mod+q" = "close_window_with_confirmation ignore-shell";
        "kitty_mod+n" = "next_window";
        "kitty_mod+j" = "next_window";
        "kitty_mod+k" = "previous_window";
        "kitty_mod+shift+j" = "focus_visible_window";
        "kitty_mod+shift+k" = "swap_with_window";
        "kitty_mod+t" = "new_tab_after";
        "kitty_mod+l" = "next_tab";
        "kitty_mod+h" = "previous_tab";
        "kitty_mod+shift+l" = "move_tab_forward";
        "kitty_mod+shift+h" = "move_tab_backward";
        "kitty_mod+r" = "set_tab_title";
        "kitty_mod+shift+t" = "detach_tab ask";
        "kitty_mod+m" = "next_layout";
        "kitty_mod+plus" = "change_font_size all +1.0";
        "kitty_mod+minus" = "change_font_size all -1.0";
        "kitty_mod+equal" = "change_font_size all 0";
        "kitty_mod+o" = "open_url_with_hints";
        "kitty_mod+i" = "kitten unicode_input";
        "kitty_mod+shift+1" = "kitty_shell window";
        "ctrl+c" = "copy_to_clipboard";
        "super+c" = "copy_to_clipboard"; # MacOS
        "ctrl+v" = "paste_from_clipboard";
        "super+v" = "paste_from_clipboard"; # MacOS
        "ctrl+shift+c" = "send_key ctrl+c";
        "ctrl+shift+v" = "send_key ctrl+v";
        "kitty_mod+up" = "kitten resize_window.py up";
        "kitty_mod+down" = "kitten resize_window.py down";
        "kitty_mod+left" = "kitten resize_window.py left";
        "kitty_mod+right" = "kitten resize-window.py right";
      };
    };
    xdg.configFile = {
      "kitty/resize_window.py".source = ./kitty-resize-window.py;
    };
  };
}

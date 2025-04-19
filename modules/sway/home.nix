{ pkgs, lib, inputs, config, systemConfig, ... }:
let
  cfg = config.wayland.windowManager.sway;
  waycfg = config.wayland.windowManager;
  theme = config.theme.set;
  viewRebuildLogCmd = "kitty --app-id=nixos_rebuild_log -- journalctl -efo cat -u nixos-rebuild.service";
  mod = "Mod4";
  # Sway does not support input or output identifier pattern matching so in order to apply settings for every
  # Apple keyboard, I have to create a new rule for each Apple keyboard I use.
  appleKeyboardIdentifiers = [
    "1452:657:Apple_Inc._Apple_Internal_Keyboard_/_Trackpad"
  ];
  appleKeyboardConfig = lib.strings.concatMapStrings
    (id: ''
      input "${id}" {
        xkb_layout us
        xkb_options caps:escape_shifted_capslock
        xkb_variant mac
      }
    '')
    appleKeyboardIdentifiers;
  cycle-sway-output = pkgs.writers.writePython3Bin
    "cycle-sway-output"
    { doCheck = false; }
    (builtins.readFile ../../misc/cycle-sway-output.py);
  cycle-sway-scale = pkgs.writers.writePython3Bin
    "cycle-sway-scale"
    { doCheck = false; }
    (builtins.readFile ../../misc/cycle-sway-scale.py);
  toggle-sway-window = pkgs.writeBabashkaScript {
    name = "toggle-sway-window";
    text = builtins.readFile ../../misc/toggle-sway-window.clj;
  };
  handle-sway-lid-on = pkgs.writers.writeBash "handle-sway-lid-on" ''
    BLOCKFILE="$HOME/.local/share/idle-sleep-block"
    if test -f "$BLOCKFILE" || swaymsg -t get_outputs --raw | grep -q '"focused": false'; then
      swaymsg output eDP-1 power off
    else
      swaymsg output eDP-1 power off
      playerctl --all-players pause
      systemctl ${waycfg.sleep.preferredType}
    fi
  '';
  handle-sway-lid-off = pkgs.writers.writeBash "handle-sway-lid-off" ''
    swaymsg output eDP-1 power on
  '';
  launch-tmux = pkgs.writers.writeBash "launch-tmux" ''
    if tmux run 2>/dev/null; then
      tmux new-window -t sandbox:
      tmux new-session -As sandbox
    else
      tmux new-session -ds config -c "$HOME/.config/nixflake"
      tmux new-session -ds media
      tmux new-session -As sandbox
    fi
  '';
  toggle-notifications = pkgs.writers.writeBash "toggle-notifications" ''
    if makoctl mode | grep -q "default"; then
      makoctl mode -s hidden
    else
      makoctl mode -s default
    fi
  '';
  wg-quick-wofi = pkgs.writers.writeBash "wg-quick-wofi" ''
    # Services that aren't enabled are never listed with list-unit command unless active
    services="$(systemctl list-unit-files --type service --no-legend 'wg-quick-*' | grep wg-quick- | cut -d ' ' -f1)"
    x="$(systemctl list-units --type service --no-legend --state active 'wg-quick-*' | grep wg-quick- | cut -d ' ' -f3 | tail -1)"
    if [ -n "$x" ]; then
      services="$(printf "%s" "$services" | sed "/^$x/d")"
      sel="$(printf "Stop %s\n%s" "$x" "$services" | wofi --dmenu --lines 4)"
    else
      sel="$(printf "%s" "$services" | wofi --dmenu --lines 4)"
    fi
    if [ "$sel" = "Stop $x" ]; then
      if systemctl stop "$x"; then
        notify-send "Stopped $x"
      else
        notify-send --urgency=critical "Failed to stop $x"
      fi
    else
      if systemctl start "$sel"; then
        notify-send "Started $sel"
        if systemctl stop "$x"; then
          notify-send "Stopped $x"
        else
          notify-send --urgency=critical "Failed to stop $x"
        fi
      else
        notify-send --urgency=critical "Failed to start $sel"
      fi
    fi
  '';
  browser = "${pkgs.librewolf}/bin/librewolf";
  terminal = "${pkgs.kitty}/bin/kitty";
in
{

  config = lib.mkIf (config.profile.graphical && pkgs.stdenv.isLinux) {

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1
        # Automatically add electron/chromium wayland flags
        export NIXOS_OZONE_WL=1
        # Fix for GTK scale issues when also using Cinnamon
        # export GDK_SCALE=1
        export GDK_DPI_SCALE=-1
        # Forgot what graphical program is being run from systemd user service
        # Could use systemd.user.extraConfig = '''DefaultEnvironment="GDK_DPI_SCALE=-1"'''
        # systemctl --user import-environment GDK_DPI_SCALE
        export GTK_THEME=${theme.gtkThemeName}; # For gnome calculator and nautilus on sway
      '';
      config = {
        fonts = {
          names = [ "FiraMono Nerd Font" ];
          style = "Regular";
          size = 8.0;
        };
        bars = [ ];
        seat.seat0.xcursor_theme = lib.mkIf (config.home.pointerCursor != null)
          "${config.home.pointerCursor.name} ${builtins.toString config.home.pointerCursor.size}";
        colors = {
          focused = {
            background = theme.bg;
            border = theme.bg3;
            childBorder = theme.bg3;
            indicator = theme.green;
            text = theme.fg;
          };
          unfocused = {
            background = theme.black;
            border = theme.bg;
            childBorder = theme.bg;
            indicator = theme.bg3;
            text = theme.fg;
          };
          focusedInactive = {
            background = theme.black;
            border = theme.bg;
            childBorder = theme.bg;
            indicator = theme.bg3;
            text = theme.fg;
          };
        };
        gaps = {
          inner = 2;
          outer = 2;
        };
        window = {
          hideEdgeBorders = "none";
          border = 1;
        };
        workspaceLayout = "tabbed";
        keybindings = {
          # Default keymaps
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";
          "${mod}+shift+h" = "move left";
          "${mod}+shift+l" = "move right";
          "${mod}+shift+k" = "move up";
          "${mod}+shift+j" = "move down";
          "${mod}+shift+q" = "kill";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";
          "${mod}+shift+1" = "move container to workspace number 1";
          "${mod}+shift+2" = "move container to workspace number 2";
          "${mod}+shift+3" = "move container to workspace number 3";
          "${mod}+shift+4" = "move container to workspace number 4";
          "${mod}+shift+5" = "move container to workspace number 5";
          "${mod}+shift+6" = "move container to workspace number 6";
          "${mod}+shift+7" = "move container to workspace number 7";
          "${mod}+shift+8" = "move container to workspace number 8";
          "${mod}+shift+9" = "move container to workspace number 9";
          "${mod}+shift+minus" = "move scratchpad";
          "${mod}+minus" = "scratchpad show";
          "${mod}+r" = "mode resize";

          # Custom sway-specific keymaps
          "${mod}+left" = "focus output left";
          "${mod}+down" = "focus output down";
          "${mod}+up" = "focus output up";
          "${mod}+right" = "focus output right";
          "${mod}+shift+left" = "move window to output left; focus output left";
          "${mod}+shift+down" = "move window to output down; focus output down";
          "${mod}+shift+up" = "move window to output up; focus output up";
          "${mod}+shift+right" = "move window to output right; focus output right";
          "${mod}+tab" = "workspace back_and_forth";
          "${mod}+less" = "focus parent";
          "${mod}+greater" = "focus child";
          "${mod}+comma" = "split toggle";
          "${mod}+period" = "split none";
          "${mod}+shift+tab" = "exec ${lib.getExe cycle-sway-output}";
          "${mod}+shift+r" = "reload; exec systemctl --user restart waybar";
          "${mod}+shift+e" = "exec swaynag -t warning -m 'Do you really want to exit sway?' -b 'Yes, exit sway' 'swaymsg exit'";
          "${mod}+shift+s" = "sticky toggle";
          "--locked ${mod}+shift+delete" = "exec systemctl ${waycfg.sleep.preferredType}";
          "--locked ${mod}+o" = "output ${waycfg.mainDisplay} power toggle";
          "--locked ${mod}+shift+o" = "output ${waycfg.mainDisplay} toggle";

          # Custom external program keymaps
          "${mod}+return" = "exec ${lib.getExe waycfg.terminal} ${lib.getExe pkgs.tmux-startup}";
          "${mod}+shift+return" = "exec ${lib.getExe waycfg.terminal}";
          "${mod}+shift+d" = "exec wofi --show run --width 800 --height 400 --term kitty";
          "${mod}+d" = "exec wofi --show drun --width 800 --height 400 --term kitty";
          "${mod}+backspace" = "exec ${lib.getExe waycfg.browser}";
          "${mod}+shift+backspace" = "exec ${lib.getExe waycfg.browser} --private-window";
          "${mod}+grave" = "exec rofimoji";
          "${mod}+c" = "exec ${lib.getExe toggle-sway-window} --id nixos_rebuild_log --width 80 --height 80 -- ${viewRebuildLogCmd}";
          "${mod}+shift+c" = "exec systemctl --user start nixos-rebuild";
          "${mod}+n" = "exec ${toggle-notifications}";
          "${mod}+p" = "exec ${lib.getExe toggle-sway-window} --id pavucontrol --width 80 --height 80 -- pavucontrol";
          "${mod}+shift+p" = "exec ${lib.getExe pkgs.cycle-pulse-sink}";
          "${mod}+a" = "exec ${lib.getExe toggle-sway-window} --id audacious --width 80 --height 80 -- audacious";
          "${mod}+shift+a" = "exec ${lib.getExe pkgs.toggle-service} record-playback";
          "${mod}+m" = "exec ${lib.getExe toggle-sway-window} --id gnome-disks -- gnome-disks"; # m = media
          "${mod}+v" = "exec ${lib.getExe toggle-sway-window} --id org.keepassxc.KeePassXC --width 80 --height 80 -- keepassxc";
          "${mod}+shift+v" = "exec ${wg-quick-wofi}";
          "${mod}+q" = "exec ${lib.getExe toggle-sway-window} --id qalculate-gtk -- qalculate-gtk";
          "${mod}+b" = "exec ${lib.getExe toggle-sway-window} --id .blueman-manager-wrapped --width 80 --height 80 -- blueman-manager";
          "${mod}+t" = "exec ${lib.getExe toggle-sway-window} --id btop --width 90 --height 90 -- kitty --app-id=btop btop";
          "${mod}+i" = "exec ${lib.getExe toggle-sway-window} --id signal --width 80 --height 80 -- signal-desktop";
          "${mod}+backslash" = "exec ${lib.getExe cycle-sway-scale}";
          "${mod}+bar" = "exec ${lib.getExe pkgs.toggle-service} wlsunset";
          "${mod}+delete" = "exec swaylock";

          # Function key keymaps
          XF86MonBrightnessDown = "exec brightnessctl set 5%-";
          XF86MonBrightnessUp = "exec brightnessctl set 5%+";
          XF86AudioPrev = "exec playerctl previous";
          XF86AudioPlay = "exec playerctl play-pause";
          XF86AudioNext = "exec playerctl next";
          XF86AudioMute = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          XF86AudioLowerVolume = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
          XF86AudioRaiseVolume = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
          "${mod}+Print" = "exec " + lib.getExe (pkgs.writeShellApplication {
            name = "sway-screenshot-selection";
            runtimeInputs = [ pkgs.coreutils-full pkgs.slurp pkgs.grim pkgs.swappy ];
            text = ''
              mkdir -p "$XDG_PICTURES_DIR/screenshots"
              grim -cg "$(slurp)" - | swappy -f -
            '';
          });
          Print = "exec " + lib.getExe (pkgs.writeShellApplication {
            name = "sway-screenshot";
            runtimeInputs = [ pkgs.coreutils-full pkgs.sway pkgs.jq pkgs.grim pkgs.swappy ];
            text = ''
              mkdir -p "$XDG_PICTURES_DIR/screenshots"
              current_output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
              grim -co "$current_output" - | swappy -f -
            '';
          });
        };
        modes = {
          resize = {
            escape = "mode default";
            return = "mode default";
            up = "move up 10 px";
            down = "move down 10 px";
            left = "move left 10 px";
            right = "move right 10 px";
            h = "resize shrink width 10 px";
            j = "resize grow height 10 px";
            k = "resize shrink height 10 px";
            l = "resize grow width 10 px";
            r = "resize set width 80 ppt height 90 ppt, move position center";
          };
        };
        # There's a big problem with how home-manager handles the input and output values
        # The ordering *does* matter so the value should be a list, not a set.
        input = {
          "type:keyboard" = {
            # man xkeyboard-config
            xkb_options = "caps:escape_shifted_capslock,altwin:swap_alt_win";
            xkb_layout = "us";
          };
          "type:touchpad" = {
            natural_scroll = "enabled";
            dwt = "enabled";
            tap = "enabled";
            tap_button_map = "lrm";
          };
        };
        output = {
          "*" = {
            background = if (waycfg.wallpaper != null) then "${waycfg.wallpaper} fill ${theme.bg}" else "${theme.bg} solid_color";
          };
          # Framework screen
          "BOE 0x095F Unknown" = {
            scale = "1.6";
            position = "0 0";
          };
          # Epson projector
          "Seiko Epson Corporation EPSON PJ 0x00000101" = {
            position = "0 0";
          };
        };
        startup = [
          # Import sway-related environment variables into systemd user services
          { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK I3SOCK DISPLAY"; }
          # Kill tmux so all shell environments contain sway-related environment variables
          { command = "tmux kill-server"; }
          { command = "systemctl is-active syncthing.service && systemctl --user start syncthing-tray.service"; always = true; }
          { command = "systemctl --user restart waybar.service"; always = true; }
          { command = "systemctl --user start wlsunset.service"; }
        ];
      };
      extraConfig = ''
        # https://github.com/emersion/xdg-desktop-portal-wlr?tab=readme-ov-file#running
        exec ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
        ${appleKeyboardConfig}
        # Any future keyboard xkb_options overrides need to go here
        bindgesture swipe:4:right workspace prev
        bindgesture swipe:4:left workspace next
        bindgesture swipe:3:right focus left
        bindgesture swipe:3:left focus right
        bindswitch lid:on exec ${handle-sway-lid-on}
        bindswitch lid:off exec ${handle-sway-lid-off}
        # Middle-click on a window title bar kills it
        bindsym button2 kill
        for_window [title=".*"] inhibit_idle fullscreen
        for_window [class=com.bitwig.BitwigStudio] inhibit_idle focus
        for_window [app_id=nmtui] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=qalculate-gtk] floating enable, move position center
        for_window [app_id=org.gnome.Calculator] floating enable, move position center
        for_window [app_id=\.?blueman-manager(-wrapped)?] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=nixos_rebuild_log] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=btop] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=pavucontrol] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=org.keepassxc.KeePassXC] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=org.rncbc.qpwgraph] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=gnome-disks] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=obsidian] move container to workspace 3
        for_window [app_id=org.libretro.RetroArch] move container to workspace 4
        for_window [class=Kodi] move container to workspace 5
        for_window [app_id=audacious] floating enable, resize set width 80 ppt height 80 ppt, move position center
        for_window [app_id=guitarix] floating disable
        for_window [app_id=dragon] sticky enable
        for_window [app_id=org.gnome.Weather] floating enable, resize set width 40 ppt height 50 ppt, move position center
      '';
      swaynag = {
        enable = true;
        settings = {
          warning = rec {
            background = theme.bgx;
            button-background = theme.bg1x;
            details-background = theme.bg1x;
            text = theme.fgx;
            button-text = theme.fgx;
            border = theme.bg2x;
            border-bottom = theme.bg3x;
            border-bottom-size = 3;
            button-border-size = 1;
          };
          error = rec {
            background = theme.bgx;
            button-background = theme.bg1x;
            details-background = theme.bg1x;
            text = theme.fgx;
            button-text = theme.fgx;
            border = theme.bg2x;
            border-bottom = theme.redx;
            border-bottom-size = 3;
            button-border-size = 1;
          };
        };
      };
    };
  };
}

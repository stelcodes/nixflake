{ pkgs, lib, inputs, config, systemConfig, ... }:
let
  cfg = config.wayland.windowManager.sway;
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
      systemctl ${cfg.sleep.preferredType}
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

  options = {
    wayland.windowManager.sway = {
      mainDisplay = lib.mkOption {
        type = lib.types.str;
        default = "eDP-1";
      };
      sleep = {
        preferredType = lib.mkOption {
          type = lib.types.enum [ "suspend" "hibernate" "hybrid-sleep" "suspend-then-hibernate" "poweroff" ];
          default = "suspend-then-hibernate";
        };
        lockBefore = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        auto = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          idleMinutes = lib.mkOption {
            type = lib.types.int;
            default = 30;
          };
        };
      };
      wallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
      };
    };
  };

  config = lib.mkIf (config.profile.graphical && config.wayland.windowManager.sway.enable && pkgs.stdenv.isLinux) {

    home = {
      packages = [
        pkgs.swaylock
        pkgs.swayidle
        pkgs.brightnessctl
        pkgs.libinput
        pkgs.wev
        pkgs.font-manager
        pkgs.wl-clipboard
        pkgs.wofi
        pkgs.adwaita-icon-theme # for the two icons in the default wofi setup
        pkgs.wlsunset
        pkgs.grim
        pkgs.slurp
        pkgs.rofimoji # Great associated word hints with extensive symbol lists to choose from
        pkgs.wtype
        pkgs.libnotify
        pkgs.pomo
        pkgs.wdisplays
        pkgs.swappy
        # pkgs.wl-screenrec # https://github.com/russelltg/wl-screenrec
        # pkgs.wlogout

        # System tooling
        pkgs.gnome-disk-utility
        # Media tooling
        pkgs.eog
        pkgs.qalculate-gtk
        pkgs.gnome-weather
      ] ++ (lib.lists.optionals config.profile.audio [
        pkgs.pamixer
        pkgs.playerctl
        pkgs.helvum # better looking than qpwgraph
        pkgs.pavucontrol
        pkgs.audacious
      ]);
      pointerCursor = {
        package = theme.cursorThemePackage;
        name = theme.cursorThemeName;
        size = 32;
        gtk.enable = true;
      };
    };

    wayland.windowManager.sway = {
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
        export TERMINAL=${terminal}
        export BROWSER=${browser};
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
          "--locked ${mod}+shift+delete" = "exec systemctl ${cfg.sleep.preferredType}";
          "--locked ${mod}+o" = "output ${cfg.mainDisplay} power toggle";
          "--locked ${mod}+shift+o" = "output ${cfg.mainDisplay} toggle";

          # Custom external program keymaps
          "${mod}+return" = "exec ${terminal} ${launch-tmux}";
          "${mod}+shift+return" = "exec ${terminal}";
          "${mod}+shift+d" = "exec wofi --show run --width 800 --height 400 --term kitty";
          "${mod}+d" = "exec wofi --show drun --width 800 --height 400 --term kitty";
          "${mod}+backspace" = "exec ${browser}";
          "${mod}+shift+backspace" = "exec ${browser} --private-window";
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
          XF86MonBrightnessUp = "exec brightnessctl set +5%";
          XF86AudioPrev = "exec playerctl previous";
          XF86AudioPlay = "exec playerctl play-pause";
          XF86AudioNext = "exec playerctl next";
          XF86AudioMute = "exec pamixer --toggle-mute";
          XF86AudioLowerVolume = "exec pamixer --decrease 5";
          XF86AudioRaiseVolume = "exec pamixer --increase 5";
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
            background = if (cfg.wallpaper != null) then "${cfg.wallpaper} fill ${theme.bg}" else "${theme.bg} solid_color";
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


    systemd.user.sockets = {
      sov = {
        Socket = {
          ListenFIFO = "%t/sov.sock";
          SocketMode = "0600";
        };
        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    };

    systemd.user.services = {

      sov = {
        Unit = {
          Description = "An overlay that shows schemas for all workspaces to make navigation in sway easier";
          PartOf = [ "sway-session.target" ];
          After = [ "sway-session.target" ];
          Requires = [ "sov.socket" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          StandardInput = "socket";
          ExecStart = "${pkgs.sov}/bin/sov";
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };

      };

      audacious = {
        Unit = {
          Description = "audacious music player";
        };
        Service = {
          ExecStart = lib.getExe pkgs.audacious;
          ExecStartPost = "-${pkgs.sway}/bin/swaymsg for_window [app_id=audacious] move scratchpad";
          Restart = "on-failure";
        };
      };

      pomo-notify = {
        Unit = {
          Description = "pomo.sh notify daemon";
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.pomo}/bin/pomo notify";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      nixos-rebuild = {
        Service = {
          Type = "exec";
          ExecStart = lib.getExe (pkgs.writeShellApplication {
            name = "nixos-rebuild-exec-start";
            runtimeInputs = [ pkgs.coreutils-full pkgs.nixos-rebuild pkgs.systemd pkgs.mpv ];
            text = ''
              notify_success() {
                notify-send "NixOS rebuild successful"
                { mpv ${pkgs.success-alert} || true; } &
                sleep 5 && kill -9 "$!"
              }
              notify_failure() {
                notify-send --urgency=critical "NixOS rebuild failed"
                { mpv ${pkgs.failure-alert} || true; } &
                sleep 5 && kill -9 "$!"
              }
              if systemctl start nixos-rebuild.service; then
                while systemctl -q is-active nixos-rebuild.service; do
                  sleep 1
                done
                if systemctl -q is-failed nixos-rebuild.service; then
                  notify_failure
                else
                  notify_success
                fi
              else
                notify_failure
              fi
            '';
          });
        };
      };

      btop = {
        Unit = {
          Description = "Btop system resource dashboard";
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.kitty} --app-id=btop ${lib.getExe pkgs.btop}";
          ExecStartPost = "-${pkgs.sway}/bin/swaymsg for_window [app_id=btop] move scratchpad";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };
      };

      swayidle.Service.ExecStop = lib.getExe (pkgs.writeShellApplication {
        name = "swayidle-cleanup";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          BLOCKFILE="$HOME/.local/share/idle-sleep-block"
          if test -f "$BLOCKFILE"; then
            rm "$BLOCKFILE"
          fi
        '';
      });

      polkit-gnome = {
        Unit = {
          Description = "GNOME polkit authentication agent";
        };
        Service = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };
      };

      syncthing-tray = lib.mkIf systemConfig.services.syncthing.enable {
        Unit = {
          Description = "Simple tray for syncthing file sync service";
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.syncthing-tray} -api '${systemConfig.services.syncthing.settings.gui.apikey}'";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };
      };

      nm-applet = {
        Unit = {
          Description = "Network manager applet";
        };
        Service = {
          ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };
      };

      record-playback = lib.mkIf config.profile.audio {
        Unit = {
          Description = "playback recording from default pulseaudio monitor";
        };
        Service = {
          RuntimeMaxSec = 500;
          Type = "forking";
          ExecStart = lib.getExe (pkgs.writeShellApplication {
            name = "record-playback-exec-start";
            runtimeInputs = [ pkgs.pulseaudio pkgs.coreutils-full pkgs.libnotify ];
            text = ''
              SAVEDIR="''${XDG_DATA_HOME:-$HOME/.local/share}/record-playback"
              mkdir -p "$SAVEDIR"
              SAVEPATH="$SAVEDIR/$(date +%Y-%m-%dT%H:%M:%S%Z).wav"
              notify-send "Starting audio recording..."
              parecord --device=@DEFAULT_MONITOR@ "$SAVEPATH" &
            '';
          });
          ExecStop = lib.getExe (pkgs.writeShellApplication {
            name = "record-playback-exec-stop";
            text = ''
              # The last couple seconds of audio gets lost so wait a lil bit before killing
              sleep 2 && kill -INT "$MAINPID"
            '';
          });
          ExecStopPost = lib.getExe (pkgs.writeShellApplication {
            name = "record-playback-exec-stop-post";
            runtimeInputs = [ pkgs.libnotify ];
            text = ''
              if [ "$EXIT_STATUS" -eq 0 ]; then
                notify-send "Stopped recording successfully"
              else
                notify-send --urgency=critical "Recording failed"
              fi
            '';
          });
          Restart = "no";
        };
      };

      blueman-applet = lib.mkIf config.profile.bluetooth {
        Unit = {
          Description = "Blueman applet";
        };
        Service = {
          ExecStart = "${pkgs.blueman}/bin/blueman-applet";
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };
      };

    };

    services = {
      swayidle = {
        enable = true;
        # Waits for commands to finish (-w) by default
        events = [
          {
            event = "before-sleep";
            command = lib.getExe (pkgs.writeShellApplication {
              runtimeInputs = [ pkgs.coreutils-full pkgs.sway pkgs.swaylock ];
              name = "swayidle-before-sleep";
              text = ''
                if ${if cfg.sleep.lockBefore then "true" else "false"}; then
                  swaylock --daemonize
                fi
                ${lib.getExe pkgs.tmux-snapshot}
                swaymsg 'output * power off'
              '';
            });
          }
          {
            event = "after-resume";
            command = lib.getExe (pkgs.writeShellApplication {
              name = "swayidle-after-resume";
              runtimeInputs = [ pkgs.coreutils-full pkgs.sway pkgs.pomo ];
              text = ''
                if [ -f "$HOME/.local/share/pomo" ]; then pomo start || true; fi
                ${pkgs.sway}/bin/swaymsg 'output * power on'
              '';
            });
          }
        ];
        timeouts = lib.mkIf cfg.sleep.auto.enable [
          {
            timeout = cfg.sleep.auto.idleMinutes * 60;
            command = lib.getExe (pkgs.writeShellApplication {
              name = "swayidle-sleepy-sleep";
              runtimeInputs = [ pkgs.coreutils-full pkgs.systemd pkgs.playerctl pkgs.gnugrep pkgs.acpi pkgs.swaylock ];
              text = ''
                set -x
                if test -f "$HOME/.local/share/idle-sleep-block"; then
                  echo "Restarting service because of idle-sleep-block file"
                  systemctl --restart swayidle.service
                elif acpi --ac-adapter | grep -q "on-line"; then
                  echo "Restarting service because laptop is plugged in"
                  systemctl --restart swayidle.service
                else
                  echo "Idle timeout reached. Night night."
                  systemctl ${cfg.sleep.preferredType}
                fi
              '';
            });
          }
        ];
        systemdTarget = "sway-session.target";
      };

      wlsunset = {
        enable = true;
        systemdTarget = "null.target";
        latitude = "38";
        longitude = "-124";
        temperature = {
          day = 7000;
          night = 4000;
        };
      };

      mako = {
        enable = true;
        anchor = "bottom-right";
        font = "FiraMono Nerd Font 10";
        extraConfig = ''
          sort=-time
          layer=overlay
          width=280
          height=110
          border-radius=5
          icons=1
          max-icon-size=64
          default-timeout=7000
          ignore-timeout=1
          padding=14
          margin=20
          outer-margin=0,0,45,0
          background-color=${theme.bg}

          [urgency=low]
          border-color=${theme.blue}

          [urgency=normal]
          border-color=${theme.bg3}

          [urgency=high]
          border-color=${theme.red}

          [mode=hidden]
          invisible=1
        '';
      };

      wayland-pipewire-idle-inhibit = {
        enable = config.profile.audio;
        package = pkgs.wayland-pipewire-idle-inhibit;
        systemdTarget = "sway-session.target";
        settings = {
          verbosity = "INFO";
          media_minimum_duration = 30;
          sink_whitelist = [ ];
          node_blacklist = [
            # Always seen as playing audio when open so just ignore these
            { name = "Bitwig Studio"; }
            { name = "Mixxx"; }
          ];
        };
      };
    };

    programs = {
      swaylock = {
        enable = true;
        settings = {
          color = theme.bgx;
          image = lib.mkIf (cfg.wallpaper != null) "${cfg.wallpaper}";
          font-size = 24;
          indicator-idle-visible = false;
          indicator-radius = 100;
          show-failed-attempts = true;
        };
      };

      waybar = {
        enable = true;
        style = ''
          @define-color bg ${theme.bg};
          @define-color bgOne ${theme.bg1};
          @define-color bgTwo ${theme.bg2};
          @define-color bgThree ${theme.bg3};
          @define-color red ${theme.red};
          ${builtins.readFile ./waybar.css}
        '';
        # Stopped working when switching between Cinnamon and Sway
        # [error] Bar need to run under Wayland
        # GTK4 get_default_display was saying it was still X11
        systemd = {
          enable = true;
          target = "sway-session.target";
        };
        settings = [{
          layer = "top";
          position = "bottom";
          height = 20;
          modules-left = [
            "sway/workspaces"
            "tray"
            "custom/pomo"
            "custom/wlsunset"
            "custom/idlesleep"
          ];
          modules-center = [ "sway/mode" ];
          modules-right = [
            "custom/rebuild"
            "cpu"
            "backlight"
            "battery"
          ] ++ (lib.lists.optionals config.profile.audio [
            "custom/recordplayback"
            "wireplumber"
          ]) ++ [
            "clock"
          ];
          "custom/pomo" = {
            format = "{} 󱎫";
            exec = "${pkgs.pomo}/bin/pomo clock";
            interval = 1;
            on-click = "${pkgs.pomo}/bin/pomo pause";
            on-click-right = "${pkgs.pomo}/bin/pomo stop";
          };
          "custom/rebuild" = {
            format = "{}";
            max-length = 12;
            interval = 2;
            exec = lib.getExe (pkgs.writeShellApplication {
              name = "waybar-rebuild-exec";
              runtimeInputs = [ pkgs.coreutils-full pkgs.systemd pkgs.gnugrep ];
              text = ''
                status="$(systemctl is-active nixos-rebuild.service || true)"
                if grep -q "inactive" <<< "$status"; then
                  printf "rebuild: "
                elif grep -q "active" <<< "$status"; then
                  printf "rebuild: "
                elif grep -q "failed" <<< "$status"; then
                  printf "rebuild: "
                fi
              '';
            });
            on-click = viewRebuildLogCmd;
          };
          "custom/recordplayback" = {
            format = "{}";
            max-length = 3;
            interval = 2;
            exec = lib.getExe (pkgs.writeShellApplication {
              name = "waybar-record-playback";
              text = ''
                if systemctl --user is-active --quiet record-playback.service; then
                  echo "🔴";
                fi
              '';
            });
          };
          "custom/idlesleep" = {
            format = "{}";
            max-length = 2;
            interval = 2;
            exec = ''if test -f "$HOME/.local/share/idle-sleep-block"; then echo '🐝'; else echo '🕸️'; fi'';
            on-click = lib.getExe (pkgs.writeShellApplication {
              name = "toggle-idle-sleep-block";
              runtimeInputs = [ pkgs.coreutils ];
              text = ''
                BLOCKFILE="$HOME/.local/share/idle-sleep-block"
                if test -f "$BLOCKFILE"; then
                  rm "$BLOCKFILE"
                else
                  touch "$BLOCKFILE"
                fi
              '';
            });
          };
          "custom/wlsunset" = {
            exec = "if systemctl --user --quiet is-active wlsunset.service; then echo ''; else echo ''; fi";
            interval = 2;
            on-click = "${lib.getExe pkgs.toggle-service} wlsunset";
            # This doesn't actually work because the only way to have dynamic tooltips is to use json mode
            # tooltip-format = "${pkgs.writers.writeFish "wlsunset-temp" ''
            #   journalctl --user -ex --unit wlsunset.service | tail | string match --regex "\d{4} K" | tail -1
            # ''}";
          };
          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "1" = "term";
              "2" = "www";
              "3" = "notes";
              "4" = "arts";
              "5" = "media";
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
            };
          };
          cpu = {
            interval = 10;
            format = "{usage} ";
            on-click = "kitty --app-id=system_monitor btop";
          };
          memory = {
            interval = 30;
            format = "{} ";
          };
          disk = {
            interval = 30;
            format = "{percentage_used} ";
          };
          wireplumber = {
            format = "{node_name} {volume} {icon}";
            format-muted = "{volume} ";
            format-icons = { default = [ "" "" ]; };
            on-click = "pavucontrol";
            on-click-right = "cycle-pulse-sink";
            on-click-middle = "helvum";
            max-volume = 100;
            scroll-step = 5;
          };
          clock = {
            format = "{:%I:%M %p %b %d} 󱛡";
            format-alt = "{:%A} 󱛡";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
          };
          battery = {
            format = "{capacity} {icon}";
            format-charging = "{capacity} ";
            format-icons = [ "" "" "" "" "" ];
            max-length = 40;
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          backlight = {
            interval = 5;
            format = "{percent} {icon}";
            format-icons = [ "" "" "" ];
          };
        }];
      };

      zathura = {
        enable = true;
        options = {
          default-fg = theme.fg;
          default-bg = theme.bg;
          statusbar-bg = theme.bg1;
          statusbar-fg = theme.fg;
        };
      };
    };


    xdg = {
      desktopEntries = {
        neovim = {
          name = "Neovim";
          genericName = "Text Editor";
          exec =
            let
              app = pkgs.writeShellScript "neovim-terminal" ''
                # Killing kitty from sway results in non-zero exit code which triggers
                # xdg-mime to use next valid entry, so we must always exit successfully
                kitty -- nvim "$1" || true
              '';
            in
            "${app} %U";
          terminal = false;
          categories = [ "Utility" "TextEditor" ];
          mimeType = [ "text/markdown" "text/plain" "text/javascript" ];
        };
      };

      configFile = {
        "wofi/config".text = "allow_images=true";
        "wofi/style.css".source = ../../misc/wofi.css;
        "pomo.cfg" = {
          onChange = ''
            ${pkgs.systemd}/bin/systemctl --user restart pomo-notify.service
          '';
          source = pkgs.writeShellScript "pomo-cfg" ''
            # This file gets sourced by pomo.sh at startup
            # I'm only caring about linux atm
            function lock_screen {
              if ${pkgs.procps}/bin/pgrep sway 2>&1 > /dev/null; then
                echo "Sway detected"
                # Only lock if pomo is still running
                test -f "$HOME/.local/share/pomo" && ${pkgs.swaylock}/bin/swaylock
                # Only restart pomo if pomo is still running
                test -f "$HOME/.local/share/pomo" && ${pkgs.pomo}/bin/pomo start
              fi
            }

            function custom_notify {
                # send_msg is defined in the pomo.sh source
                block_type=$1
                if [[ $block_type -eq 0 ]]; then
                    echo "End of work period"
                    send_msg 'End of a work period. Locking Screen!'
                    ${pkgs.playerctl}/bin/playerctl --all-players pause
                    ${pkgs.mpv}/bin/mpv ${pkgs.pomo-alert} || sleep 10
                    lock_screen &
                elif [[ $block_type -eq 1 ]]; then
                    echo "End of break period"
                    send_msg 'End of a break period. Time for work!'
                    ${pkgs.mpv}/bin/mpv ${pkgs.pomo-alert}
                else
                    echo "Unknown block type"
                    exit 1
                fi
            }
            POMO_MSG_CALLBACK="custom_notify"
            POMO_WORK_TIME=30
            POMO_BREAK_TIME=5
          '';
        };
        "gajim/theme/nord.css".text = ''
          .gajim-outgoing-nickname {
              color: ${theme.magenta};
          }
          .gajim-incoming-nickname {
              color: ${theme.yellow};
          }
          .gajim-url {
              color: ${theme.blue};
          }
          .gajim-status-online {
              color: ${theme.green};
          }
          .gajim-status-away {
              color: ${theme.red};
          }
        '';
        "swappy/config".text = ''
          [Default]
          save_dir=$XDG_PICTURES_DIR/screenshots
          save_filename_format=swappy-%FT%X.png
          show_panel=false
          line_size=5
          text_size=20
          text_font=sans-serif
          paint_mode=brush
          early_exit=true
          fill_shape=false
        '';
        "rofimoji.rc".text = ''
          action = copy
          selector = wofi
          files = [emojis]
          skin-tone = neutral
        '';

      } // (if config.theme.set ? gtkConfigFiles then config.theme.set.gtkConfigFiles else { });

      mimeApps = {
        # https://www.iana.org/assignments/media-types/media-types.xhtml
        # Check /run/current-system/sw/share/applications for .desktop entries
        # Take MimeType value from desktop entries and turn into nix code with this substitution:
        # s/\v([^;]+);/"\1" = [ "org.gnome.eog.desktop" ];\r/g
        enable = true;
        defaultApplications = {
          "application/http" = [ "firefox.desktop" ];
          "text/html" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "application/bzip2" = [ "org.gnome.FileRoller.desktop" ];
          "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
          "application/vnd.android.package-archive" = [ "org.gnome.FileRoller.desktop" ];
          "application/vnd.ms-cab-compressed" = [ "org.gnome.FileRoller.desktop" ];
          "application/vnd.debian.binary-package" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-7z-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-ace" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-alz" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-apple-diskimage" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-ar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-archive" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-arj" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-brotli" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-bzip-brotli-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-bzip" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-bzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-bzip1" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-bzip1-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-cabinet" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-cd-image" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-compress" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-cpio" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-chrome-extension" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-deb" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-ear" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-ms-dos-executable" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-gtar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-gzip" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-gzpostscript" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-java-archive" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lha" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lhz" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lrzip" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lrzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lz4" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lzip" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lzma" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lzma-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lzop" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-lz4-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-ms-wim" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-rar-compressed" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-rpm" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-source-rpm" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-rzip" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-rzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-tarz" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-tzo" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-stuffit" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-war" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-xar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-xz-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-zip" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-zip-compressed" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-zstd-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-zoo" = [ "org.gnome.FileRoller.desktop" ];
          "application/zip" = [ "org.gnome.FileRoller.desktop" ];
          "application/zstd" = [ "org.gnome.FileRoller.desktop" ];
          "image/bmp" = [ "org.gnome.eog.desktop" ];
          "image/gif" = [ "org.gnome.eog.desktop" ];
          "image/jpeg" = [ "org.gnome.eog.desktop" ];
          "image/jpg" = [ "org.gnome.eog.desktop" ];
          "image/pjpeg" = [ "org.gnome.eog.desktop" ];
          "image/png" = [ "org.gnome.eog.desktop" ];
          "image/tiff" = [ "org.gnome.eog.desktop" ];
          "image/webp" = [ "org.gnome.eog.desktop" ];
          "image/x-bmp" = [ "org.gnome.eog.desktop" ];
          "image/x-gray" = [ "org.gnome.eog.desktop" ];
          "image/x-icb" = [ "org.gnome.eog.desktop" ];
          "image/x-ico" = [ "org.gnome.eog.desktop" ];
          "image/x-png" = [ "org.gnome.eog.desktop" ];
          "image/x-portable-anymap" = [ "org.gnome.eog.desktop" ];
          "image/x-portable-bitmap" = [ "org.gnome.eog.desktop" ];
          "image/x-portable-graymap" = [ "org.gnome.eog.desktop" ];
          "image/x-portable-pixmap" = [ "org.gnome.eog.desktop" ];
          "image/x-xbitmap" = [ "org.gnome.eog.desktop" ];
          "image/x-xpixmap" = [ "org.gnome.eog.desktop" ];
          "image/x-pcx" = [ "org.gnome.eog.desktop" ];
          "image/svg+xml" = [ "org.gnome.eog.desktop" ];
          "image/svg+xml-compressed" = [ "org.gnome.eog.desktop" ];
          "image/vnd.wap.wbmp" = [ "org.gnome.eog.desktop" ];
          "image/x-icns" = [ "org.gnome.eog.desktop" ];
          "application/ogg" = [ "audacious.desktop" ];
          "application/x-cue" = [ "audacious.desktop" ];
          "application/x-ogg" = [ "audacious.desktop" ];
          "application/xspf+xml" = [ "audacious.desktop" ];
          "audio/aac" = [ "audacious.desktop" ];
          "audio/flac" = [ "audacious.desktop" ];
          "audio/midi" = [ "audacious.desktop" ];
          "audio/mp3" = [ "audacious.desktop" ];
          "audio/mp4" = [ "audacious.desktop" ];
          "audio/mpeg" = [ "audacious.desktop" ];
          "audio/mpegurl" = [ "audacious.desktop" ];
          "audio/ogg" = [ "audacious.desktop" ];
          "audio/prs.sid" = [ "audacious.desktop" ];
          "audio/wav" = [ "audacious.desktop" ];
          "audio/x-flac" = [ "audacious.desktop" ];
          "audio/x-it" = [ "audacious.desktop" ];
          "audio/x-mod" = [ "audacious.desktop" ];
          "audio/x-mp3" = [ "audacious.desktop" ];
          "audio/x-mpeg" = [ "audacious.desktop" ];
          "audio/x-mpegurl" = [ "audacious.desktop" ];
          "audio/x-ms-asx" = [ "audacious.desktop" ];
          "audio/x-ms-wma" = [ "audacious.desktop" ];
          "audio/x-musepack" = [ "audacious.desktop" ];
          "audio/x-s3m" = [ "audacious.desktop" ];
          "audio/x-scpls" = [ "audacious.desktop" ];
          "audio/x-stm" = [ "audacious.desktop" ];
          "audio/x-vorbis+ogg" = [ "audacious.desktop" ];
          "audio/x-wav" = [ "audacious.desktop" ];
          "audio/vnd.wave" = [ "audacious.desktop" ];
          "audio/x-wavpack" = [ "audacious.desktop" ];
          "audio/x-xm" = [ "audacious.desktop" ];
          "audio/x-opus+ogg" = [ "audacious.desktop" ];
          "audio/x-aiff" = [ "audacious.desktop" ];
          "x-content/audio-cdda" = [ "audacious.desktop" ];
          "text/markdown" = [ "neovim.desktop" ];
          "text/plain" = [ "neovim.desktop" ];
          "application/x-zerosize" = [ "neovim.desktop" ]; # empty files
          "video/vnd.avi" = [ "mpv.desktop" ];
          "video/mkv" = [ "mpv.desktop" ];
          # "application/x-mobipocket-ebook" = [ "org.pwmt.zathura.desktop" ];
          "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
          "application/oxps" = [ "org.pwmt.zathura.desktop" ];
          "application/x-fictionbook" = [ "org.pwmt.zathura.desktop" ];
          "x-scheme-handler/obsidian" = [ "obsidian.desktop" ];
        };
      };

      dataFile = {
        "audacious/internet-radio-stations.audpl".source = ../../misc/internet-radio-stations.audpl;
      };
    };

  };
}

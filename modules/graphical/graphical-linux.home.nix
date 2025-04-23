{ pkgs, config, inputs, lib, ... }:
let
  theme = config.theme.set;
  waycfg = config.wayland.windowManager;
  inhibitIdleFile = "$HOME/.local/state/inhibit-idle";
  toggle-inhibit-idle = pkgs.writeShellApplication {
    name = "toggle-inhibit-idle";
    runtimeInputs = [ pkgs.coreutils-full ];
    text = ''
      file="${inhibitIdleFile}"
      if test -f "$file"; then
        rm "$file"
      else
        touch "$file"
      fi
    '';
  };
  niri-adjust-scale = pkgs.writePythonApplication {
    name = "niri-adjust-scale";
    text = builtins.readFile ./niri-adjust-scale.py;
  };
  sessionTargets = lib.foldlAttrs
    (acc: sessionName: deps: acc // {
      "${sessionName}-session" = {
        Unit =
          let depsFull = lib.map (depName: "${depName}.service") deps; in
          {
            BindsTo = [ "graphical-session.target" ];
            Wants = depsFull;
            Before = depsFull;
          };
      };
    })
    { }
    waycfg.sessions;
  sessionServices = lib.foldlAttrs
    (acc: sessionName: deps: acc // (lib.lists.foldl
      (acc: depName: acc //
        {
          "${depName}" = {
            Unit = {
              BindsTo = lib.mkForce [ "graphical-session.target" ];
              After = lib.mkForce [ "graphical-session.target" ];
            };
            Install = lib.mkForce { };
          };
        })
      { }
      deps
    ))
    { }
    waycfg.sessions;
  # https://gitlab.gnome.org/GNOME/glib/-/blob/2.76.2/gio/gdesktopappinfo.c#L2701-2713
  # Might require xdg-desktop-portal-gnome as default xdg-open method
  xdg-terminal-exec = pkgs.writeShellApplication {
    name = "xdg-terminal-exec";
    text = ''
      if command -v "$TERMINAL" &> /dev/null; then
        "$TERMINAL" "$@"
      else
        printf "TERMINAL not set" >&2
        exit 1
      fi
    '';
  };
  pw-rotate-sink = pkgs.writeShellApplication {
    name = "pw-rotate-sink";
    runtimeInputs = [ pkgs.coreutils-full pkgs.jq pkgs.wireplumber pkgs.pipewire ];
    text = builtins.readFile ./pw-rotate-sink.sh;
  };
in
{

  options = {
    wayland.windowManager = {
      mainDisplay = lib.mkOption {
        type = lib.types.str;
        default = "eDP-1";
      };
      sleep = {
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
      terminal = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.kitty;
      };
      browser = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.librewolf;
      };
      sessions = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
      };
    };
  };

  config = lib.mkIf (config.profile.graphical && pkgs.stdenv.isLinux) {

    home = {
      packages = ([
        waycfg.terminal
        xdg-terminal-exec
        waycfg.browser
        pkgs.material-icons # for mpv uosc
        # pkgs.mpv-unify # custom mpv python wrapper
        pkgs.keepassxc
        pkgs.gnome-disk-utility
        pkgs.eog
        pkgs.qalculate-gtk
        pkgs.gnome-weather
        pkgs.font-manager
        pkgs.file-roller
        pkgs.brightnessctl
        pkgs.wev
        pkgs.wl-clipboard
        pkgs.wofi
        pkgs.adwaita-icon-theme # for the two icons in the default wofi setup
        pkgs.rofimoji # Great associated word hints with extensive symbol lists to choose from
        pkgs.wdisplays
        pkgs.libnotify # for notify-send
        # pkgs.kooha # Doesn't work with niri atm
        # pkgs.wl-screenrec # https://github.com/russelltg/wl-screenrec
        # pkgs.wlogout
        niri-adjust-scale
      ] ++ (lib.lists.optionals config.profile.audio [
        pkgs.playerctl
        pkgs.helvum # better looking than qpwgraph
        pkgs.pavucontrol
        pw-rotate-sink
      ]));
      sessionVariables = {
        TERMINAL = lib.getExe waycfg.terminal;
        BROWSER = lib.getExe waycfg.browser;
      };
      pointerCursor = {
        package = theme.cursorThemePackage;
        name = theme.cursorThemeName;
        size = 24;
        gtk.enable = true;
      };
    };

    xdg = {
      configFile = {
        # "niri/config.kdl".source = ./niri.kdl;
        "niri/config.kdl".source = pkgs.writeTextFile {
          name = "config.kdl";
          checkPhase = ''
            ${lib.getExe pkgs.niri} validate --config "$out"
          '';
          text = builtins.readFile ./niri.kdl;
        };
        "rofimoji.rc".text = /* ini */ ''
          action = copy
          selector = wofi
          files = [emojis]
          skin-tone = neutral
        '';
        "wofi/config".text = /* ini */ ''
          allow_images=true
          width=800
          height=400
          term=kitty
          show=drun
        '';
        "wofi/style.css".source = ./wofi.css;
        "gajim/theme/default.css".text = ''
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
      } // (if config.theme.set ? gtkConfigFiles then config.theme.set.gtkConfigFiles else { }); #catppuccin
      portal = {
        # https://mozilla.github.io/webrtc-landing/gum_test.html
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gnome ];
        config.sway = {
          default = "gtk";
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr";
        };
        configPackages = [ pkgs.niri ];
      };
      mimeApps = {
        enable = true;
        # Works with xdgOpenUsePortal true or false
        defaultApplications =
          let
            browser = [ "librewolf.desktop" ];
            archiver = [ "org.gnome.FileRoller.desktop" ];
            imageViewer = [ "org.gnome.eog.desktop" ];
            musicPlayer = [ "audacious.desktop" ];
            videoPlayer = [ "mpv.desktop" ];
            documentViewer = [ "org.pwmt.zathura.desktop" ];
            textEditor = [ "neovim.desktop" ];
          in
          {
            "application/http" = browser;
            "application/https" = browser;
            "text/html" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
          };
      };
    };

    programs = {

      mpv = {
        enable = true;
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

      gnome-shell = {
        theme = {
          name = theme.gtkThemeName;
          package = theme.gtkThemePackage;
        };
      };

      swaylock = {
        enable = true;
        settings = {
          color = theme.bgx;
          image = lib.mkIf (waycfg.wallpaper != null) "${waycfg.wallpaper}";
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
          @define-color fg ${theme.fg};
          ${builtins.readFile ./waybar.css}
        '';
        # Stopped working when switching between Cinnamon and Sway
        # [error] Bar need to run under Wayland
        # GTK4 get_default_display was saying it was still X11
        systemd.enable = true;
        settings = [{
          layer = "bottom";
          position = "bottom";
          height = 20;
          margin = "0px 5px 5px 5px";
          modules-left = [
            "tray"
            "custom/pomo"
            "custom/wlsunset"
            "custom/inhibitidle"
            "custom/recordplayback"
          ];
          modules-center = [ "sway/mode" "sway/workspaces" "niri/workspaces" ];
          modules-right = [
            "cpu"
            "backlight"
            "battery"
          ] ++ (lib.lists.optionals config.profile.audio [
            "wireplumber"
          ]) ++ [
            "clock"
          ];
          "custom/pomo" = {
            format = "{} ⏱️";
            exec = "${pkgs.pomo}/bin/pomo clock";
            interval = 1;
            on-click = "${pkgs.pomo}/bin/pomo pause";
            on-click-right = "${pkgs.pomo}/bin/pomo stop";
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
          "custom/inhibitidle" = {
            format = "{}";
            max-length = 2;
            interval = 2;
            exec = lib.getExe (pkgs.writeShellApplication {
              name = "display-wayland-inhibit-idle";
              runtimeInputs = [ pkgs.coreutils-full ];
              text = ''
                if test -f "${inhibitIdleFile}"; then
                  printf '☕';
                else
                  printf '💤';
                fi
              '';
            });
            on-click = lib.getExe toggle-inhibit-idle;
          };
          "custom/wlsunset" = {
            exec = "if systemctl --user --quiet is-active wlsunset.service; then echo '🌙'; else echo '☀️'; fi";
            interval = 2;
            on-click = "${lib.getExe pkgs.toggle-service} wlsunset";
          };
          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{icon}";
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
          wireplumber = lib.mkIf config.profile.audio {
            format = "{node_name} {volume} {icon}";
            format-muted = "{volume} ";
            format-icons = { default = [ "" "" ]; };
            on-click = lib.getExe pw-rotate-sink;
            on-click-right = lib.getExe pkgs.pavucontrol;
            on-click-middle = lib.getExe pkgs.helvum;
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
        mappings = {
          "<Up>" = "navigate previous";
          "<Left>" = "navigate previous";
          "<Down>" = "navigate next";
          "<Right>" = "navigate next";
        };
      };
    };

    systemd.user.targets = sessionTargets;

    systemd.user.services = (lib.mkMerge [
      sessionServices
      {
        swayidle = {
          Service.ExecStopPost = lib.getExe (pkgs.writeShellApplication {
            name = "swayidle-cleanup";
            runtimeInputs = [ pkgs.coreutils-full ];
            text = ''
              rm "${inhibitIdleFile}" || true
            '';
          });
        };
        swaybg = lib.mkIf (waycfg.wallpaper != null) {
          Service.ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i ${waycfg.wallpaper}";
        };
        xwayland-satellite = {
          Service.ExecStart = "${lib.getExe pkgs.xwayland-satellite} :12";
        };
        pomo-notify = {
          Unit.Description = "pomo.sh notify daemon";
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.pomo}/bin/pomo notify";
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
      }
    ]);

    services = {
      network-manager-applet.enable = true;
      blueman-applet.enable = true;
      polkit-gnome.enable = true;
      gnome-keyring.enable = true;
      swayidle = {
        enable = true;
        # Waits for commands to finish (-w) by default
        events = [
          {
            event = "before-sleep";
            command = lib.getExe (pkgs.writeShellApplication {
              runtimeInputs = [ pkgs.coreutils pkgs.swaylock pkgs.sway pkgs.niri ];
              name = "swayidle-before-sleep";
              text = ''
                if ${if waycfg.sleep.lockBefore then "true" else "false"}; then
                  swaylock -f
                fi
                swaymsg 'output * power off' || true
                niri msg action power-off-monitors || true
              '';
            });
          }
          {
            event = "after-resume";
            command = lib.getExe (pkgs.writeShellApplication {
              name = "swayidle-after-resume";
              runtimeInputs = [ pkgs.coreutils-full pkgs.sway pkgs.niri ];
              text = ''
                swaymsg 'output * power on' || true
                niri msg action power-on-monitors || true
              '';
            });
          }
        ];
        timeouts = lib.mkIf waycfg.sleep.auto.enable [
          {
            timeout = waycfg.sleep.auto.idleMinutes * 60;
            command = lib.getExe (pkgs.writeShellApplication {
              name = "swayidle-idle-sleep";
              runtimeInputs = [ pkgs.coreutils-full pkgs.systemd ];
              text = ''
                if test -f "${inhibitIdleFile}"; then
                  printf "Restarting timer because %s exists" "${inhibitIdleFile}"
                  systemctl --restart swayidle.service
                elif ${lib.getExe' pkgs.pmutils "on_ac_power"}; then
                  printf "Restarting timer because machine is plugged in"
                  systemctl --restart swayidle.service
                else
                  printf "Idle timeout reached. Night night."
                  systemctl sleep
                fi
              '';
            });
          }
        ];
      };

      wlsunset = {
        enable = true;
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
          text-color=${theme.fg}

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
        "org/gnome/settings-daemon/plugins/media-keys" = {
          screensaver = [ "<Super>Delete" ];
        };
        "org/gnome/desktop/wm/keybindings" = {
          minimize = [ "<Shift><Super>m" ];
          maximize = [ "<Super>m" ];
          toggle-fullscreen = [ "<Super>f" ];
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

    wayland.windowManager.sessions = {
      sway = [
        "waybar"
        "swayidle"
        "network-manager-applet"
        "polkit-gnome"
        "blueman-applet"
        "wlsunset"
        "wayland-pipewire-idle-inhibit"
        "pomo-notify"
        "gnome-keyring"
      ];
      niri = [
        "swaybg"
        "waybar"
        "swayidle"
        "network-manager-applet"
        "polkit-gnome"
        "blueman-applet"
        "wlsunset"
        "wayland-pipewire-idle-inhibit"
        "pomo-notify"
        "gnome-keyring"
        "xwayland-satellite"
      ];
    };

  };
}

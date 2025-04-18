{ pkgs, config, inputs, lib, ... }:
let
  theme = config.theme.set;
  waycfg = config.wayland.windowManager;
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
in
{

  options = {
    wayland.windowManager = {
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
        waycfg.browser
        pkgs.material-icons # for mpv uosc
        # pkgs.mpv-unify # custom mpv python wrapper
        pkgs.keepassxc
        # pkgs.ungoogled-chromium
        pkgs.gnome-disk-utility
        pkgs.eog
        pkgs.qalculate-gtk
        pkgs.gnome-weather
        pkgs.font-manager

        pkgs.brightnessctl
        pkgs.wev
        pkgs.wl-clipboard
        pkgs.wofi
        pkgs.adwaita-icon-theme # for the two icons in the default wofi setup
        pkgs.rofimoji # Great associated word hints with extensive symbol lists to choose from
        pkgs.wdisplays
        # pkgs.wl-screenrec # https://github.com/russelltg/wl-screenrec
        # pkgs.wlogout
      ] ++ (lib.lists.optionals config.profile.audio [
        pkgs.playerctl
        pkgs.helvum # better looking than qpwgraph
        pkgs.pavucontrol
      ]));

      sessionVariables = {
        TERMINAL = lib.getExe waycfg.terminal;
        BROWSER = lib.getExe waycfg.browser;
      };
    };

    xdg.configFile = {
      "niri/config.kdl".source = ./niri.kdl;
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
            "custom/idlesleep"
          ];
          modules-center = [ "sway/mode" "sway/workspaces" "niri/workspaces" ];
          modules-right = [
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

    systemd.user.targets = sessionTargets;

    systemd.user.services = (lib.mkMerge [
      {
        swaybg = lib.mkIf (waycfg.wallpaper != null) {
          Service = {
            ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i ${waycfg.wallpaper}";
          };
        };
        xwayland-satellite = {
          Service = {
            ExecStart = "${lib.getExe pkgs.xwayland-satellite} :01";
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
      }
      sessionServices
    ]);

    services = {
      network-manager-applet.enable = true;
      blueman-applet.enable = true;
      polkit-gnome.enable = true;
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
                  systemctl ${waycfg.sleep.preferredType}
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
        "xwayland-satellite"
      ];
    };

  };
}

{
  pkgs,
  config,
  lib,
  ...
}:
let
  theme = config.theme.set;
  waycfg = config.wayland;
  niri-adjust-scale = pkgs.writePythonApplication {
    name = "niri-adjust-scale";
    text = builtins.readFile ./niri-adjust-scale.py;
  };
  sessionTargets = lib.foldlAttrs (
    acc: sessionName: sessionOpts:
    acc
    // {
      "${sessionName}-session" = {
        Unit =
          let
            servicesFull = lib.map (serviceName: "${serviceName}.service") sessionOpts.services;
          in
          {
            BindsTo = [ "graphical-session.target" ];
            Wants = servicesFull;
            Before = servicesFull;
          };
      };
    }
  ) { } waycfg.sessions;
  sessionServices = lib.foldlAttrs (
    acc: sessionName: sessionOpts:
    acc
    // (lib.lists.foldl (
      acc: serviceName:
      acc
      // {
        "${serviceName}" = {
          Unit = {
            BindsTo = lib.mkForce [ "graphical-session.target" ];
            After = lib.mkForce [ "graphical-session.target" ];
          };
          Install = lib.mkForce { };
        };
      }
    ) { } sessionOpts.services)
  ) { } waycfg.sessions;
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
    runtimeInputs = [
      pkgs.coreutils-full
      pkgs.jq
      pkgs.wireplumber
      pkgs.pipewire
    ];
    text = builtins.readFile ./pw-rotate-sink.sh;
  };
  monitor-power = pkgs.writeShellApplication {
    name = "monitor-power";
    runtimeInputs = [
      pkgs.coreutils-full
      pkgs.systemd
    ];
    text = builtins.concatStringsSep "\n" (
      lib.mapAttrsToList (
        sessionName: sessionOpts: # sh
        ''
          if systemctl --user -q is-active ${sessionName}.service; then
            if [ "$1" = "on" ]; then
              ${sessionOpts.monitorOn}
            elif [ "$1" = "off" ]; then
              ${sessionOpts.monitorOff}
            fi
          fi
        '') waycfg.sessions
    );
  };
  niri-pick-color = pkgs.writeShellApplication {
    name = "niri-pick-color";
    runtimeInputs = [
      pkgs.wl-clipboard
      pkgs.niri
      pkgs.gnugrep
    ];
    text = ''
      set -o pipefail
      niri msg pick-color | grep -oE '#[[:alnum:]]{6}' | wl-copy
    '';
  };
  niri-rename-workspace = pkgs.writeShellApplication {
    name = "niri-rename-workspace";
    runtimeInputs = [
      pkgs.niri
      pkgs.wofi
      pkgs.gawk
    ];
    text = ''
      # If wofi is canceled, abort and do nothing
      # If wofi input is empty, unset workspace name
      # Else rename workspace with provided name
      response=$(wofi --dmenu --hide-scroll --lines=1)
      trimmed=$(awk '{$1=$1;print}' <<< "$response")
      if [ -z "$trimmed" ]; then
        niri msg action unset-workspace-name
      else
        niri msg action set-workspace-name "$response"
      fi
    '';
  };
  wofi-toggle = pkgs.writeShellApplication {
    name = "wofi-toggle";
    runtimeInputs = [
      pkgs.wofi
      pkgs.procps
    ];
    text = ''
      pkill wofi-wrapped || exec wofi "$@"
    '';
  };
in
{

  options = {
    wayland = {
      mainMonitor = lib.mkOption {
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
        default = pkgs.mullvad-browser;
      };
      sessions = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              monitorOn = lib.mkOption {
                type = lib.types.str;
              };
              monitorOff = lib.mkOption {
                type = lib.types.str;
              };
              services = lib.mkOption {
                type = lib.types.listOf lib.types.str;
              };
            };
          }
        );
        default = { };
      };
    };
  };

  config = lib.mkIf (config.profile.graphical && pkgs.stdenv.isLinux) {

    home = {
      packages = (
        [
          waycfg.terminal
          xdg-terminal-exec
          waycfg.browser
          pkgs.material-icons # for mpv uosc
          # pkgs.mpv-unify # custom mpv python wrapper
          pkgs.keepassxc
          pkgs.gnome-disk-utility
          pkgs.eog
          pkgs.qalculate-gtk
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
          pkgs.chafa # images in terminal, telescope-media-files dep
          pkgs.seahorse # pulled in anyway by SSH_ASKPASS confirmation prompt
          # pkgs.kooha # Doesn't work with niri atm
          # pkgs.wl-screenrec # https://github.com/russelltg/wl-screenrec
          # pkgs.wlogout
          niri-adjust-scale
          niri-pick-color
          niri-rename-workspace
          monitor-power
          wofi-toggle
        ]
        ++ (lib.lists.optionals config.profile.audio [
          pkgs.playerctl
          pkgs.helvum # better looking than qpwgraph
          pkgs.pavucontrol
          pw-rotate-sink
        ])
      );
      sessionVariables = {
        TERMINAL = lib.getExe waycfg.terminal;
        BROWSER = lib.getExe waycfg.browser;
        # https://man7.org/linux/man-pages/man1/ssh.1.html#ENVIRONMENT
        # https://blog.burakcankus.com/2025/03/15/keepassxc-and-ssh-agent-setup.html
        SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
        SSH_ASKPASS_REQUIRE = "prefer";
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        QT_QPA_PLATFORM = "wayland";
        # QT6 only https://github.com/NixOS/nixpkgs/issues/342115
        QT_QPA_PLATFORMTHEME = "gtk3";
        NIXOS_OZONE_WL = "1";
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };
      pointerCursor = {
        # https://vibhorjaiswal.github.io/Cursor-Test/
        enable = true;
        package = theme.cursorThemePackage;
        name = theme.cursorThemeName;
        size = 24;
        gtk.enable = true;
      };
      # Default wallpaper
      file."pictures/wallpaper/2f20c35a7e430a9edcbece0f9c24f280.jpg".source = pkgs.fetchurl {
        url = "https://i.imgur.com/jo5NfMD.jpeg";
        hash = "sha256-iO7ZO5wM4bx13uOtGOWEIjN89bi+jiSe0zNWbKHGTyY=";
      };
    };

    xdg = {
      configFile = {
        "niri/config.kdl".source = pkgs.writeTextFile {
          name = "config.kdl";
          checkPhase = ''
            ${lib.getExe pkgs.niri} validate --config "$out"
          '';
          text = builtins.readFile ./niri.kdl;
        };
        "rofimoji.rc".text = # ini
          ''
            action = copy
            selector = wofi
            files = [emojis]
            skin-tone = neutral
          '';
        "wofi/config".text = # ini
          ''
            allow_images=true
            term=kitty
            show=drun
            no_actions=true
            key_expand=Tab
            insensitive=true
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
      } // (if config.theme.set ? gtkConfigFiles then config.theme.set.gtkConfigFiles else { }); # catppuccin
      portal = {
        # https://mozilla.github.io/webrtc-landing/gum_test.html
        # Config files: /etc/profiles/per-user/admin/share/xdg-desktop-portal
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gnome
        ];
        config = {
          common = {
            default = [ "gtk" ];
          };
          sway = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Screenshot" = "wlr";
            "org.freedesktop.impl.portal.ScreenCast" = "wlr";
          };
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Access" = "gtk";
            "org.freedesktop.impl.portal.Notification" = "gtk";
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
            "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          };
        };
      };
      desktopEntries = {
        mullvad-browser = {
          name = "Mullvad Browser";
          genericName = "Web Browser";
          icon = "mullvad-browser";
          exec = "mullvad-browser --new-window %U";
          terminal = false;
          type = "Application";
          categories = [
            "Network"
            "WebBrowser"
            "Security"
          ];
          mimeType = [
            "text/html"
            "text/xml"
            "application/xhtml+xml"
            "application/vnd.mozilla.xul+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
          ];
        };
      };
      mimeApps = {
        enable = true;
        # Works with xdgOpenUsePortal true or false
        defaultApplications =
          let
            browser = [ "mullvad-browser.desktop" ];
            imageViewer = [ "org.gnome.eog.desktop" ];
            mpvPlayer = [ "mpv.desktop" ];
          in
          {
            "application/http" = browser;
            "application/https" = browser;
            "text/html" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "image/bmp" = imageViewer;
            "image/gif" = imageViewer;
            "image/jpeg" = imageViewer;
            "image/jpg" = imageViewer;
            "image/jxl" = imageViewer;
            "image/pjpeg" = imageViewer;
            "image/png" = imageViewer;
            "image/tiff" = imageViewer;
            "image/webp" = imageViewer;
            "image/svg+xml" = imageViewer;
            "image/svg+xml-compressed" = imageViewer;
            "application/ogg" = mpvPlayer;
            "audio/aac" = mpvPlayer;
            "audio/aiff" = mpvPlayer;
            "audio/m4a" = mpvPlayer;
            "audio/mp3" = mpvPlayer;
            "audio/ogg" = mpvPlayer;
            "audio/wav" = mpvPlayer;
            "video/mpeg" = mpvPlayer;
            "video/mp4" = mpvPlayer;
            "video/ogg" = mpvPlayer;
            "video/avi" = mpvPlayer;
            "video/flv" = mpvPlayer;
            "video/mkv" = mpvPlayer;
            "audio/x-matroska" = mpvPlayer;
            "application/x-matroska" = mpvPlayer;
            "video/webm" = mpvPlayer;
            "audio/webm" = mpvPlayer;
            "audio/vorbis" = mpvPlayer;
            "audio/flac" = mpvPlayer;
            "audio/mp4" = mpvPlayer;
            "audio/opus" = mpvPlayer;
            "audio/m3u" = mpvPlayer;
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
          cache = "yes";
          demuxer-max-bytes = "4096MiB";
          gapless-audio = "no";
          hwdec = "yes";
          gpu-context = lib.mkIf pkgs.stdenv.isLinux "wayland";
        };
        scripts =
          let
            p = pkgs.mpvScripts;
          in
          [
            p.uosc
            p.thumbfast
            p.mpv-cheatsheet
            p.videoclip
          ]
          ++ lib.lists.optionals pkgs.stdenv.isLinux [
            p.mpris
          ];
        # scriptOpts = {
        #   videoclip = {
        #   };
        # };
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
        systemd.enable = true;
        settings = [
          {
            layer = "bottom";
            position = "bottom";
            height = 20;
            margin = "0px 5px 5px 5px";
            modules-left = [
              "tray"
              "custom/ianny"
              "custom/wlsunset"
              "custom/wlinhibit"
              "custom/recordscreen"
              "custom/recordplayback"
              "sway/mode"
              "sway/workspaces"
              "niri/workspaces"
            ];
            modules-right =
              [
                "cpu"
                "backlight"
                "battery"
              ]
              ++ (lib.lists.optionals config.profile.audio [
                "wireplumber"
              ])
              ++ [
                "clock"
              ];
            "custom/ianny" = {
              exec = # sh
                "if systemctl --user --quiet is-active ianny.service; then echo '🩷'; else echo '🩶'; fi";
              interval = 1;
              on-click = "${lib.getExe pkgs.toggle-service} ianny";
            };
            "custom/recordscreen" = {
              exec = # sh
                "systemctl --user --quiet is-active record-screen.service && echo '🔴'";
              interval = 1;
              on-click = "systemctl --user stop record-screen";
            };
            "custom/recordplayback" = {
              exec = # sh
                "systemctl --user --quiet is-active record-playback.service && echo '🟠'";
              interval = 1;
              on-click = "systemctl --user stop record-playback";
            };
            "custom/wlinhibit" = {
              exec = # sh
                "if systemctl --user --quiet is-active wlinhibit.service; then printf '☕'; else printf '💤'; fi";
              interval = 1;
              on-click = "${lib.getExe pkgs.toggle-service} wlinhibit";
            };
            "custom/wlsunset" = {
              exec = # sh
                "if systemctl --user --quiet is-active wlsunset.service; then echo '🌙'; else echo '☀️'; fi";
              interval = 1;
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
              format-icons = {
                default = [
                  ""
                  ""
                ];
              };
              on-click = lib.getExe pw-rotate-sink;
              on-click-right = lib.getExe pkgs.pavucontrol;
              on-click-middle = lib.getExe pkgs.helvum;
              max-volume = 100;
              scroll-step = 5;
            };
            clock = {
              format = "{:%I:%M %p} 󱛡";
              format-alt = "{:%a %b %d} 󱛡";
              calendar = {
                mode = "month";
                mode-mon-col = 3;
                weeks-pos = "right";
                format = {
                  months = "<b>{}</b>";
                  weekdays = "<span color='${theme.yellow}'><b>{}</b></span>";
                  weeks = "<span color='${theme.green}'><b>W{}</b></span>";
                  today = "<span color='${theme.red}'><b>{}</b></span>";
                };
              };
              tooltip-format = "<tt><small>{calendar}</small></tt>";
            };
            battery = {
              format = "{capacity} {icon}";
              format-charging = "{capacity} ";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
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
              format-icons = [
                ""
                ""
                ""
              ];
            };
          }
        ];
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

    systemd.user.services = (
      lib.mkMerge [
        sessionServices
        {
          trayscale = {
            Unit = {
              After = [ "waybar.service" ];
              StartLimitIntervalSec = "5m";
              StartLimitBurst = "100";
            };
            Service = {
              ExecStartPre = "${pkgs.systemd}/bin/busctl --user --no-pager status fr.arouillard.waybar";
              Restart = "on-failure";
              RestartSec = "1s";
            };
          };
          ianny = {
            Unit = {
              BindsTo = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service.ExecStart = lib.getExe pkgs.ianny;
          };
          wlinhibit = {
            # Service is off by default, only started upon user request
            Unit = {
              BindsTo = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service.ExecStart = "${pkgs.wlinhibit}/bin/wlinhibit";
          };
          xwayland-satellite = {
            Service.ExecStart = "${lib.getExe pkgs.xwayland-satellite} :12";
          };
          gtklock = {
            Service.ExecStart = lib.getExe pkgs.gtklock;
          };
          record-screen = {
            Unit = {
              BindsTo = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              RuntimeMaxSec = 60 * 5; # 5 minutes
              KillSignal = "SIGINT";
              ExecStart = lib.getExe (
                pkgs.writeShellApplication {
                  name = "record-screen-exec-start";
                  runtimeInputs = [
                    pkgs.gpu-screen-recorder
                    pkgs.coreutils
                  ];
                  text = ''
                    output_dir="$HOME/videos/screen-recorder"
                    timestamp=$(date +%Y-%m-%dT%H:%M:%S%Z)
                    mkdir -p "$output_dir"
                    gpu-screen-recorder -w portal -o "$output_dir/$timestamp.mp4"
                  '';
                }
              );
            };
          };
          record-playback = lib.mkIf config.profile.audio {
            Unit = {
              Description = "playback recording from default pulseaudio monitor";
              BindsTo = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              RuntimeMaxSec = 60 * 5; # 5 minutes
              Type = "forking";
              ExecStart = lib.getExe (
                pkgs.writeShellApplication {
                  name = "record-playback-exec-start";
                  runtimeInputs = [
                    pkgs.pulseaudio
                    pkgs.coreutils-full
                    pkgs.libnotify
                  ];
                  text = ''
                    SAVEDIR="''${XDG_DATA_HOME:-$HOME/.local/share}/record-playback"
                    mkdir -p "$SAVEDIR"
                    SAVEPATH="$SAVEDIR/$(date +%Y-%m-%dT%H:%M:%S%Z).wav"
                    notify-send "Starting audio recording..."
                    parecord --device=@DEFAULT_MONITOR@ "$SAVEPATH" &
                  '';
                }
              );
              ExecStop = lib.getExe (
                pkgs.writeShellApplication {
                  name = "record-playback-exec-stop";
                  text = ''
                    # The last couple seconds of audio gets lost so wait a lil bit before killing
                    sleep 2 && kill -INT "$MAINPID"
                  '';
                }
              );
              ExecStopPost = lib.getExe (
                pkgs.writeShellApplication {
                  name = "record-playback-exec-stop-post";
                  runtimeInputs = [ pkgs.libnotify ];
                  text = ''
                    if [ "$EXIT_STATUS" -eq 0 ]; then
                      notify-send "Stopped recording successfully"
                    else
                      notify-send --urgency=critical "Recording failed"
                    fi
                  '';
                }
              );
              Restart = "no";
            };
          };
        }
      ]
    );

    services = {
      network-manager-applet.enable = true;
      blueman-applet.enable = true;
      trayscale.enable = false;
      polkit-gnome.enable = true;
      ssh-agent.enable = true; # Needs DISPLAY, make sure to start after compositor runs systemctl import-environment
      syncthing.tray.enable = config.services.syncthing.enable;

      swayidle = {
        enable = true;
        # Waits for commands to finish (-w) by default
        events =
          [
            {
              event = "after-resume";
              command = "${lib.getExe monitor-power} on"; # In case monitor powered off before sleep started
            }
          ]
          ++ lib.lists.optionals waycfg.sleep.lockBefore [
            {
              event = "before-sleep";
              command = lib.getExe (
                pkgs.writeShellApplication {
                  name = "swayidle-before-sleep";
                  runtimeInputs = [
                    pkgs.coreutils
                    pkgs.playerctl
                    pkgs.systemd
                  ];
                  text = ''
                    playerctl -a pause || true
                    systemctl --user start gtklock
                  '';
                }

              );
            }
          ];
        timeouts = lib.mkIf waycfg.sleep.auto.enable [
          {
            timeout = waycfg.sleep.auto.idleMinutes * 60;
            # wlinhibit currently doesn't work with niri
            # command = "${pkgs.systemd}/bin/systemctl sleep";
            command = lib.getExe (
              pkgs.writeShellApplication {
                name = "swayidle-idle-timeout";
                runtimeInputs = [
                  pkgs.systemd
                  pkgs.playerctl
                  pkgs.coreutils
                ];
                text = ''
                  if systemctl --user is-active -q wlinhibit.service; then
                    systemctl --user restart swayidle.service
                  else
                    playerctl -a pause || true
                    systemctl sleep
                  fi
                '';
              }
            );
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
        settings = {
          anchor = "bottom-right";
          font = "FiraMono Nerd Font 10";
          sort = "-time";
          layer = "overlay";
          width = "280";
          height = "110";
          border-radius = "5";
          icons = "1";
          max-icon-size = "64";
          default-timeout = "7000";
          ignore-timeout = "1";
          padding = "14";
          margin = "20";
          outer-margin = "0,0,45,0";
          background-color = theme.bg;
          text-color = theme.fg;
          "urgency=low" = {
            border-color = theme.blue;
          };
          "urgency=normal" = {
            border-color = theme.bg3;
          };
          "urgency=high" = {
            border-color = theme.red;
          };
          "mode=hidden" = {
            invisible = "1";
          };
        };
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

      wpaperd = {
        enable = true;
        settings = {
          default = {
            path = "/home/${config.admin.username}/pictures/wallpaper";
            duration = "60s";
            mode = "center";
            sorting = "ascending";
          };
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

    wayland.sessions =
      let
        sharedServices = [
          "waybar"
          "swayidle"
          "network-manager-applet"
          "polkit-gnome"
          "blueman-applet"
          "wlsunset"
          "wayland-pipewire-idle-inhibit"
          "ssh-agent"
          "trayscale"
          "wpaperd"
        ];
      in
      {
        # sway = {
        #   monitorOn = "${pkgs.sway}/bin/swaymsg 'output ${waycfg.mainMonitor} power on'";
        #   monitorOff = "${pkgs.sway}/bin/swaymsg 'output ${waycfg.mainMonitor} power off'";
        #   services = sharedServices;
        # };
        niri = {
          monitorOn = "${pkgs.niri}/bin/niri msg output ${waycfg.mainMonitor} on";
          monitorOff = "${pkgs.niri}/bin/niri msg output ${waycfg.mainMonitor} off";
          services = sharedServices ++ [
            "xwayland-satellite"
          ];
        };
      };

  };
}

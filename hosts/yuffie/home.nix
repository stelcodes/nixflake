{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
{

  home = {
    sessionVariables = {
      STEAM_FORCE_DESKTOPUI_SCALING = 2;
    };
    stateVersion = "24.11";
    packages = [
      pkgs.signal-desktop
      pkgs.gimp3-with-plugins
      # pkgs.wineWowPackages.waylandFull
      (pkgs.createBrowserApp {
        name = "Bandcamp";
        icon = "music";
        url = "https://bandcamp.com";
      })
      (pkgs.createBrowserApp {
        name = "Discord";
        icon = "discord";
        url = "https://app.discord.com";
      })
      (pkgs.createBrowserApp {
        name = "Weather";
        icon = "weather";
        url = "https://weatherstar.netbymatt.com/?kiosk=true";
      })
      (pkgs.createBrowserApp {
        name = "Excalidraw";
        icon = "draw.io";
        url = "https://excalidraw.com";
      })
      (pkgs.createBrowserApp {
        name = "Photopea";
        icon = "color-picker";
        url = "https://www.photopea.com";
      })
      (pkgs.createBrowserApp {
        name = "Squoosh";
        icon = "image-optimizer";
        url = "https://www.squoosh.app";
      })
      pkgs.kdePackages.k3b
      pkgs.calibre
      pkgs.deploy-rs
      pkgs.open-browser-app
      pkgs.mgba
      # pkgs.duckstation
      pkgs.video-with-subs
      # pkgs.d-spy
      # pkgs.lollypop
      # pkgs.gnome-podcasts
      # pkgs.fractal
      pkgs.mkvtoolnix
      pkgs.oniux
      # (pkgs.typst.withPackages (p: [ p.touying ]))
      # pkgs.pympress
      # pkgs.tuba
      # pkgs.inkscape-with-extensions
      pkgs.nvtopPackages.intel # integrated intel gpu usage
      # pkgs.gpu-screen-recorder-gtk # super easy screen recorder
      # inputs.audio.packages.${pkgs.system}.bitwig-studio5-2
      # pkgs.nixos-anywhere
      # pkgs.wg-killswitch
      pkgs.wireguard-tools
      pkgs.usbimager
    ];
  };
  wayland = {
    mainMonitor = "eDP-1";
    sleep = {
      lockBefore = true;
      auto = {
        enable = false;
        idleMinutes = 15;
      };
    };
    wallpaper = pkgs.wallpaper.anime-girl-coffee;
  };
  programs.beets = {
    enable = true;
    # package = pkgs.python3.pkgs.beets.override {
    #   pluginOverrides = {
    #     # alternatives = {
    #     #   enable = true;
    #     #   propagatedBuildInputs = [ pkgs.python3.pkgs.beets-alternatives ];
    #     # };
    #     bandcamp = {
    #       enable = true;
    #       propagatedBuildInputs = [ (pkgs.python3.pkgs.beetcamp.override { beets = pkgs.beets-minimal; }) ];
    #     };
    #   };
    # };
    settings = {
      directory = "/shares/beets/library";
      library = "/shares/beets/beets.db";
      import = {
        move = true;
      };
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/python-modules/beets/default.nix
      plugins = [
        "musicbrainz"
        "fetchart"
        "embedart"
        # "chroma"
        # "spotify"
        # "bandcamp"
      ];
      permissions = {
        file = 644;
        dir = 755;
      };
      fetchart = {
        auto = true;
        minwidth = 800;
        maxwidth = 1200;
      };
      embedart = {
        auto = true;
        maxwidth = 600;
        quality = 80;
        # If file has embedded art already, compare to fetched art
        # Not working, not sure why
        # compare_threshold = 20;
      };
    };
  };
  programs.nushell = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -a";
      rm = "rm -i";
      mv = "mv -pi";
      r = "rsync -ah"; # use --delete-delay when necessary
      gs = "git status";
      gl = "git log";
      glf = "git log --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%an%C(reset) %C(cyan)%cr%C(reset) %s %C(green)%d%C(reset)' --graph";
      d = "dua --stay-on-filesystem interactive";
      ssh-key-create = "ssh-keygen -a 100 -t ed25519 -f ./id_ed25519 -C \"$(whoami)@$(hostname)@$(date +'%Y-%m-%d')\"";
      date-sortable = "^date +%Y-%m-%dT%H:%M:%S%Z"; # ISO 8601 date format with local timezone
      date-sortable-utc = "^date -u +%Y-%m-%dT%H:%M:%S%Z"; # ISO 8601 date format with UTC timezone
    };
    settings = {
      #  config nu --doc | nu-highlight | less -R
      show_banner = false;
      edit_mode = "vi";
      cursor_shape = {
        vi_insert = "blink_line";
        vi_normal = "blink_block";
      };
      completions.external = {
        enable = true;
        max_results = 200;
      };
      buffer_editor = "nvim";
      history = {
        file_format = "sqlite";
        max_size = 100000;
        sync_on_enter = true; # History is saved immediately
        isolation = true;
      };
      rm.always_trash = true; # trash by default
      keybindings = [
        {
          name = "job_to_foreground";
          modifier = "control";
          keycode = "char_z";
          mode = [
            "emacs"
            "vi_insert"
            "vi_normal"
          ];
          event = {
            send = "executehostcommand";
            cmd = "job unfreeze";
          };
        }
        {
          name = "fuzzy_history";
          modifier = "control";
          keycode = "char_r";
          mode = [
            "emacs"
            "vi_normal"
            "vi_insert"
          ];
          event = {
            send = "executehostcommand";
            cmd = ''
              commandline edit --replace (
                history
                | get command
                | enumerate
                | reverse
                | uniq
                | each { |it| $"($it.item)" }
                | str join (char -i 0)
                | fzf --read0 --layout reverse --query (commandline) --scheme history --preview-window hidden --bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort' --header 'Press CTRL-Y to copy command into clipboard'
                | decode utf-8
                | str trim
              )
            '';
          };
        }
        # abbr
        {
          name = "abbr_menu";
          modifier = "none";
          keycode = "space";
          mode = [
            "emacs"
            "vi_normal"
            "vi_insert"
          ];
          event = [
            {
              send = "menu";
              name = "abbr_menu";
            }
            {
              edit = "insertchar";
              value = " ";
            }
          ];
        }
      ];
      menus = [
        {
          name = "abbr_menu";
          only_buffer_difference = false;
          marker = "none";
          type = {
            layout = "columnar";
            columns = 1;
            col_width = 20;
            col_padding = 2;
          };
          style = {
            text = "green";
            selected_text = "green_reverse";
            description_text = "yellow";
          };
          source = lib.setType "nushell-inline" {
            expr =
              #nu
              ''
                { |buffer, position|
                    let match = (scope aliases | where name == $buffer)
                    if ($match | is-empty) { {value: $buffer} } else { $match | each { |it| {value: ($it.expansion) }} }
                }
              '';
          };
        }
      ];
    };
    envFile.text = ''
      $env.PROMPT_INDICATOR_VI_INSERT = ""
      $env.PROMPT_INDICATOR_VI_NORMAL = ""
    '';
  };
  services = {
    syncthing = {
      # http://localhost:8384
      enable = false;
      tray.enable = false;
    };
  };
}

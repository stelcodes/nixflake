{
  pkgs,
  inputs,
  config,
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
      pkgs.ungoogled-chromium
      pkgs.gimp3-with-plugins
      pkgs.wineWowPackages.waylandFull
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
      pkgs.duckstation
      (pkgs.writePythonApplication {
        name = "vws";
        runtimeInputs = [ pkgs.ffmpeg ];
        text = builtins.readFile ../../misc/video-with-subs.py;
      })
      pkgs.d-spy
      pkgs.lollypop
      pkgs.gnome-podcasts
      pkgs.fractal
      pkgs.mkvtoolnix
      pkgs.oniux
      (pkgs.typst.withPackages (p: [ p.touying ]))
      pkgs.pympress
      pkgs.tuba
      pkgs.inkscape-with-extensions
      pkgs.nvtopPackages.intel # integrated intel gpu usage
      pkgs.gpu-screen-recorder-gtk # super easy screen recorder
      inputs.audio.packages.${pkgs.system}.bitwig-studio5-2
      pkgs.nixos-anywhere
      pkgs.wg-killswitch
      pkgs.wireguard-tools
      pkgs.usbimager
    ];
  };
  wayland = {
    mainMonitor = "eDP-1";
    sleep = {
      lockBefore = true;
      auto = {
        enable = true;
        idleMinutes = 15;
      };
    };
    wallpaper = pkgs.wallpaper.anime-girl-coffee;
  };
  programs.nushell = {
    enable = true;
    settings = {
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
    };
    envFile.text = ''
      $env.PROMPT_INDICATOR_VI_INSERT = ""
      $env.PROMPT_INDICATOR_VI_NORMAL = ""
    '';
  };
  services = {
    syncthing = {
      enable = false;
      settings = {
        options = {
          localAnnounceEnabled = false;
        };
        gui = {
          tls = true;
          user = config.admin.username;
          password = "$2b$05$d8XcRmg/wsYS4hFhFhcyjePNS8rnHLEhU5ZfDNJiV/8gEc8Ks6NUW";
        };
      };
    };
  };
}

{ pkgs, ... }: {

  home = {
    sessionVariables = {
      STEAM_FORCE_DESKTOPUI_SCALING = 2;
    };
    stateVersion = "24.11";
    packages = [
      pkgs.signal-desktop
      pkgs.ungoogled-chromium
      pkgs.gimp3-with-plugins
      pkgs.jellyfin-media-player
      pkgs.musicpod
      pkgs.wineWowPackages.waylandFull
      pkgs.thunderbird
      (pkgs.createBrowserApp { name = "Bandcamp"; url = "https://bandcamp.com"; })
      (pkgs.createBrowserApp { name = "Discord"; url = "https://app.discord.com"; })
      pkgs.kdePackages.k3b
      pkgs.calibre
      pkgs.deploy-rs
      pkgs.open-browser-app
      pkgs.mgba
      pkgs.duckstation
      (pkgs.writePythonApplication {
        name = "video-with-subs";
        runtimeInputs = [ pkgs.ffmpeg ];
        text = builtins.readFile ../../misc/video-with-subs.py;
      })
      pkgs.d-spy
      pkgs.lollypop
      pkgs.bitwig-studio
    ];
  };
  wayland.windowManager = {
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
}

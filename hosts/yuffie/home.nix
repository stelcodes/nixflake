{ pkgs, ... }: {

  home = {
    sessionVariables = {
      STEAM_FORCE_DESKTOPUI_SCALING = 2;
    };
    stateVersion = "24.11";
    packages = [
      # pkgs.davinci-resolve not working
      # pkgs.obsidian
      # pkgs.discord-firefox
      # pkgs.signal-desktop
      # pkgs.retroarch-loaded
      # pkgs.sshfs
      # pkgs.nfs-utils
      # pkgs.kodi-loaded
      # pkgs.rembg
      pkgs.ungoogled-chromium
      pkgs.gimp-with-plugins
      pkgs.jellyfin-media-player
      pkgs.musicpod
    ];
  };
  wayland.windowManager = {
    mainDisplay = "eDP-1";
    sleep = {
      preferredType = "hybrid-sleep";
      lockBefore = true;
      auto = {
        enable = true;
        idleMinutes = 15;
      };
    };
    wallpaper = pkgs.wallpaper.anime-girl-coffee;
  };
}

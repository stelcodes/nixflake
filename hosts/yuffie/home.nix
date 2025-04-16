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
      # pkgs.gimp-with-plugins
      # pkgs.nfs-utils
      # pkgs.kodi-loaded
      # pkgs.jellyfin-media-player
      # pkgs.rembg
    ];
  };
  wayland.windowManager = {
    mainDisplay = "eDP-1";
    sleep = {
      preferredType = "suspend-then-hibernate";
      lockBefore = true;
      auto = {
        enable = true;
        idleMinutes = 15;
      };
    };
    wallpaper = pkgs.wallpaper.anime-girl-coffee;
  };
}

{ pkgs, ... }:
{
  home = {
    stateVersion = "23.11";
    packages = [
      # pkgs.obsidian
      # pkgs.spotify
      # pkgs.signal-desktop
      # pkgs.wineWowPackages.stagingFull
      # pkgs.projectm
    ];
  };

  wayland = {
    mainMonitor = "eDP-1";
    sleep = {
      lockBefore = false;
      auto = {
        enable = true;
        idleMinutes = 15;
      };
    };
    wallpaper = pkgs.wallpaper.rei-moon;
  };
}

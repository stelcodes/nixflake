{ pkgs, ... }:
{
  home = {
    stateVersion = "23.11";
    packages = [
    ];
  };

  services.wlsunset.systemdTarget = "null.target";

  wayland = {
    sleep = {
      lockBefore = false;
      auto.enable = false;
    };
    wallpaper = pkgs.wallpaper.anime-girl-cat;
  };
}

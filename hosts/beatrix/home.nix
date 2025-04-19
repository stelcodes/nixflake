{ pkgs, ... }: {
  home = {
    stateVersion = "23.11";
    packages = [
      pkgs.kodi-loaded
      pkgs.retroarch-loaded
    ];
  };

  services.wlsunset.systemdTarget = "null.target";

  wayland.windowManager.sway = {
    sleep = {
      lockBefore = false;
      auto.enable = false;
    };
    wallpaper = pkgs.wallpaper.anime-girl-cat;
  };
}

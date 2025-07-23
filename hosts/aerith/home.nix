{ pkgs, ... }:
{
  config = {
    home = {
      packages = [
        pkgs.signal-desktop
      ];
      stateVersion = "25.05";
    };
    services.syncthing = {
      enable = true;
      tray.enable = true;
    };
    wayland.keyboardOptions = "caps:escape_shifted_capslock";
  };
}

{ pkgs, ... }:
{
  config = {
    home = {
      packages = [
        pkgs.signal-desktop
      ];
      stateVersion = "25.05";
    };
  };
}

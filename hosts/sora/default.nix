{
  lib,
  pkgs,
  config,
  ...
}:
{

  imports = [
    ./hardware.nix
    ./disks.nix
  ];

  config = {

    profile = {
      audio = false;
      bluetooth = false;
      graphical = false;
      battery = false;
      virtualHost = false;
    };

    # boot.kernel.sysctl = { "vm.swappiness" = 10; };
    # zramSwap.enable = true;

    services = {
      caddy = {
        enable = true;
      };
      postgresql = {
        enable = true;
        basicSetup.enable = true;
      };
    };

    system.stateVersion = "25.05";

  };
}

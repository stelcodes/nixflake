{ ... }:
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
      virtual = true;
      virtualHost = false;
    };

    # boot.kernel.sysctl = { "vm.swappiness" = 10; };
    # zramSwap.enable = true;

    system.stateVersion = "25.05";

  };
}

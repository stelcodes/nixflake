{ inputs, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
  ];

  config = {

    boot.loader.systemd-boot.enable = false;

    profile = {
      audio = false;
      bluetooth = false;
      graphical = true;
      battery = false;
      virtualHost = false;
    };

    system.stateVersion = "24.05";

  };
}

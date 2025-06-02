{ inputs, ... }:
{

  imports = [
    ./hardware.nix
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

    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
            priority = 1;
          };
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    # boot.kernel.sysctl = { "vm.swappiness" = 10; };
    # zramSwap.enable = true;

    system.stateVersion = "24.11";

  };
}

{ inputs, ... }: {

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
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "500M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
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

    system.stateVersion = "24.11";

  };
}

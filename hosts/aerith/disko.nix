{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # The file containing the password, only used during initial setup
                passwordFile = "/tmp/secret.key";
                # Allows TRIM requests, an optimization for SSDs
                # https://askubuntu.com/a/243527
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  ###############################################################
                  # Helpful stuff:
                  # btrfs subvolume list -at /
                  ###############################################################
                  # Creating new subvolumes manually after disko install:
                  # mount -t btrfs -o subvolid=0 /dev/mapper/crypted /mnt/toplvlbtrfs
                  # cd /mnt/toplvlbtrfs && btrfs subvolume create home-snapshots
                  ###############################################################
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home-snapshots" = {
                      mountpoint = "/home/.snapshots";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "32G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

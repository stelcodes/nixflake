{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
  ];

  profile = {
    audio = true;
    bluetooth = true;
    graphical = true;
    battery = false;
    virtualHost = true;
    virtual = false;
  };

  activities = {
    coding = true;
    gaming = true;
    djing = true;
    jamming = true;
  };

  powerManagement = {
    enable = true;
    powerUpCommands = ''
      ${pkgs.hdparm}/bin/hdparm -B 127 /dev/sdb
      ${pkgs.hdparm}/bin/hdparm -B 127 /dev/sdc
    '';
  };

  age.secrets = {
    pvpn-fast-wg-quick-config.file = ../../secrets/meshify-pvpn-fast-wg-quick-config.age;
    pvpn-sc-wg-quick-config.file = ../../secrets/meshify-pvpn-sc-wg-quick-config.age;
    vpn-1.file = ../../secrets/vpn-1.age;
  };

  environment.systemPackages = [
    pkgs.btrfs-progs
  ];

  programs = {
    firejail.enable = true;
    k3b.enable = true;
  };

  fileSystems."/run/media/archive" = {
    device = "/dev/disk/by-uuid/b61e7c5c-ef1b-402c-bc2f-28ec33770319";
    fsType = "btrfs";
  };

  services = {
    # getty.autologinUser = config.admin.username;
    snapper = {
      # Must create btrfs snapshots subvolume manually
      # sudo btrfs subvolume create <mount_point>/.snapshots
      snapshotInterval = "hourly"; # (terrible naming, this is a calendar value not a timespan)
      cleanupInterval = "12hours";
      # https://wiki.archlinux.org/title/Snapper
      # http://snapper.io/manpages/snapper-configs.html
      configs = {
        archive = {
          SUBVOLUME = "/run/media/archive";
          ALLOW_USERS = [ config.admin.username ];
          FSTYPE = "btrfs";
          SPACE_LIMIT = "0.5";
          FREE_LIMIT = "0.2";
          NUMBER_CLEANUP = true;
          NUMBER_LIMIT = "20";
          NUMBER_LIMIT_IMPORTANT = "20";
          NUMBER_MIN_AGE = "21600"; # 6 hours
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_MIN_AGE = "21600"; # 6 hours
          TIMELINE_LIMIT_HOURLY = "6";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "8";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
        };
      };
    };
    udev.packages = [ pkgs.android-udev-rules ];

    # nfs.server = {
    #   # Don't forget to open firewall
    #   # allowedTCPPorts = [ 2049 ];
    #   # allowedUDPPorts = [ 2049 ];
    #   enable = true;
    #   # https://www.man7.org/linux/man-pages/man5/exports.5.html
    #   exports = ''
    #     /run/media/archive/tmp 192.168.1.101(ro,nohide,insecure,no_subtree_check)
    #   '';
    # };

    samba = {
      # https://nixos.wiki/wiki/Samba
      # smbpasswd -a my_user
      enable = true;
      securityType = "user";
      openFirewall = true;
      extraConfig = # ini
        ''
          # Guests are disabled by default
          server string = smbnix
          netbios name = smbnix
          # Speed increase?
          use sendfile = yes
          hosts allow = 192.168.0. 192.168.1. 127.0.0.1 localhost
          hosts deny = 0.0.0.0/0
        '';
      shares = {
        private = {
          # path = "/var/lib/samba/private";
          path = "/run/media/archive";
          browseable = "yes"; # default
          "read only" = "no";
          "guest ok" = "no"; # default
          "create mask" = "0644";
          "directory mask" = "0755"; # default
          "force user" = "stel";
          "force group" = "users";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };

  # systemd.tmpfiles.rules = [
  #   "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
  # ];

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
    wg-quick.interfaces = {
      pvpn-fast = {
        configFile = config.age.secrets.pvpn-fast-wg-quick-config.path;
        autostart = false;
      };
      pvpn-sc = {
        configFile = config.age.secrets.pvpn-sc-wg-quick-config.path;
        autostart = false;
      };
      vpn-1 = {
        configFile = config.age.secrets.vpn-1.path;
        autostart = false;
      };
    };
  };

  nixpkgs.overlays = [ ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # https://nixos.wiki/wiki/OBS_Studio
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  # Enable swap on luks
  boot.initrd.luks.devices."luks-9cb8c555-ba9c-4ae7-880f-5b16bf71579d".device =
    "/dev/disk/by-uuid/9cb8c555-ba9c-4ae7-880f-5b16bf71579d";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}

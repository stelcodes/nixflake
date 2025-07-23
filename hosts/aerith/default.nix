{ config, lib, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  profile = {
    physical = true;
    virtualHost = false;
    bluetooth = true;
    audio = true;
    graphical = true;
    battery = true;
  };

  activities = {
    coding = true;
  };

  # load broadcom wireless driver
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ broadcom_sta ];

  # blacklist similar modules to avoid collision
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
  ];

  services = {
    xserver.xkb.options = "caps:escape_shifted_capslock";
    snapper = {
      # Must create btrfs snapshots subvolume manually
      # sudo btrfs subvolume create <mount_point>/.snapshots
      snapshotInterval = "hourly"; # (terrible naming, this is a calendar value not a timespan)
      persistentTimer = true; # Trigger snapshot immediately if last trigger was missed
      cleanupInterval = "1d";
      # https://wiki.archlinux.org/title/Snapper
      # http://snapper.io/manpages/snapper-configs.html
      configs = {
        home = {
          # sudo btrfs subvolume create /home/.snapshots
          SUBVOLUME = "/home";
          ALLOW_USERS = [ config.admin.username ]; # Users that can "operate a config"
          FSTYPE = "btrfs";
          SPACE_LIMIT = "0.5"; # Limit of filesystem space to use
          FREE_LIMIT = "0.2"; # Limit of filesystem space that should be free
          NUMBER_CLEANUP = true; # Should the number cleanup algorithm be used
          NUMBER_LIMIT = "20"; # How many numbered snapshots are kept upon cleanup
          NUMBER_LIMIT_IMPORTANT = "20"; # How many numbered snapshots marked with "important" are kept upon cleanup
          TIMELINE_CREATE = true; # Should hourly snapshots be taken
          TIMELINE_CLEANUP = true; # Should hourly snapshots be cleaned up
          TIMELINE_LIMIT_HOURLY = "6"; # How many hourly snapshots are kept upon cleanup
          TIMELINE_LIMIT_DAILY = "6"; # How many daily snapshots are kept upon cleanup
          TIMELINE_LIMIT_WEEKLY = "6"; # How many weekly snapshots are kept upon cleanup
          TIMELINE_LIMIT_MONTHLY = "6"; # # How many monthly snapshots are kept upon cleanup
          TIMELINE_LIMIT_QUARTERLY = "0"; # How many quarterly snapshots are kept upon cleanup
          TIMELINE_LIMIT_YEARLY = "0"; # How many yearly snapshots are kept upon cleanup
        };
      };
    };
  };

  # source: https://docs.syncthing.net/users/firewall.html
  networking.firewall.allowedTCPPorts = [
    22000
  ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];

  hardware.facetimehd = {
    enable = true;
    withCalibration = true;
  };

  system.stateVersion = "25.05";
}

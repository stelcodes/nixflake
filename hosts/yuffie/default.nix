{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  imports = [
    # See https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  profile = {
    audio = true;
    bluetooth = true;
    graphical = true;
    battery = true;
    virtual = false;
    virtualHost = false;
  };

  activities = {
    coding = true;
    gaming = false;
    djing = false;
    jamming = false;
  };

  # Needed to create Rasp Pi SD images
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # 22000 for Syncthing: https://docs.syncthing.net/users/firewall.html
  networking = {
    firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  programs = {
    sniffnet.enable = true;
    nix-ld.enable = true;
  };

  fonts.packages = [ pkgs.google-fonts ];

  services = {
    # https://bitsheriff.dev/posts/2025-01-05_how-to-use-the-fingerprint-reader-on-arch/
    # https://wiki.archlinux.org/title/Fprint
    # Use fprintd-enroll to register right index finger
    # When enabled, swaylock only accepts fingerprints https://github.com/swaywm/swaylock/issues/61
    fprintd.enable = true;
    jellyfin = {
      enable = false;
      group = "multimedia";
      openFirewall = false;
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = "--operator=${config.admin.username}"; # For trayscale
    };
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

  security.wrappers = {
    # Necessary for burning CDs with k3b
    cdrdao = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrdao}/bin/cdrdao";
    };
    cdrecord = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrtools}/bin/cdrecord";
    };
  };

  # man tmpfiles.d
  # Special bits - the x in x770
  # 4 - setuid: This file when executed will inherit owner
  # 2 - setgid: This file when executed will inherit group OR new files inside this directory will inherit group
  # 1 - sticky: All files inside this directory can only be modified by owner (i.e. /tmp)
  systemd.tmpfiles.rules = [
    "d /srv/multimedia 2770 root multimedia -"
  ];

  security.pam.pam-parallel = {
    enable = true;
    applyToModules = [
      "gtklock"
      "ly"
    ];
    methods = {
      fprint = {
        description = "Fingerprint";
        rule = "auth sufficient ${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
      password = {
        description = "Password";
        rule = "auth sufficient ${config.security.pam.package}/lib/security/pam_unix.so likeauth nullok try_first_pass";
      };
    };
  };

  system.stateVersion = "24.11";

}

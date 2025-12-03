{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
{

  imports = [
    # See https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    ./hardware-configuration.nix
    ./disk-config.nix

    # inputs.copyparty.nixosModules.default
  ];

  profile = {
    audio = true;
    bluetooth = true;
    graphical = true;
    battery = true;
    physical = true;
    virtualHost = false;
  };

  activities = {
    coding = true;
    gaming = false;
    djing = false;
    jamming = false;
  };

  admin.username = "stel";

  users = {
    users = {
      # copyparty = {
      #   description = "Service user for copyparty";
      #   group = "copyparty";
      #   extraGroups = [
      #     "shares"
      #   ];
      #   home = "/var/lib/copyparty";
      #   isSystemUser = true;
      # };
      jellyfin.extraGroups = [ "shares" ];
    };
    # groups = {
    #   copyparty = { };
    # };
  };

  nixpkgs.overlays = [ inputs.copyparty.overlays.default ];

  # Needed to create Rasp Pi SD images
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Syncthing: https://docs.syncthing.net/users/firewall.html
  networking = {
    hosts = {
      "127.0.0.1" = [
        # "books.stelclementine.com"
        "media.stelclementine.com"
        "syncthing-gui.stelclementine.com"
        # "files.stelclementine.com"
      ];
    };
    firewall = {
      allowedTCPPorts = [
        22000
      ];
      allowedUDPPorts = [
        22000
        21027
      ];
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
    fprintd.enable = false;
    postgresql = {
      enable = true;
      basicSetup.enable = true;
    };
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--operator=${config.admin.username}" ]; # For trayscale
      permitCertUid = "caddy";
    };
    syncthing = {
      enable = true;
      user = config.admin.username;
      group = "shares";
      overrideDevices = false;
      overrideFolders = false;
      guiAddress = "127.0.0.1:8384";
      dataDir = "/home/${config.admin.username}/.local/state/syncthing";
      settings = {
        gui = {
          insecureSkipHostcheck = true;
        };
        options = {
          listenAddresses = [
            # sync.stelclementine.com:22000
            "tcp://100.75.57.114:22000"
            "quic://100.75.57.114:22000"
          ];
          urAccepted = -1;
          localAnnounceEnabled = true;
          globalAnnounceEnabled = false;
          natEnabled = false;
        };
      };
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
          TIMELINE_LIMIT_HOURLY = "7"; # How many hourly snapshots are kept upon cleanup
          TIMELINE_LIMIT_DAILY = "7"; # How many daily snapshots are kept upon cleanup
          TIMELINE_LIMIT_WEEKLY = "0"; # How many weekly snapshots are kept upon cleanup
          TIMELINE_LIMIT_MONTHLY = "0"; # # How many monthly snapshots are kept upon cleanup
          TIMELINE_LIMIT_QUARTERLY = "0"; # How many quarterly snapshots are kept upon cleanup
          TIMELINE_LIMIT_YEARLY = "0"; # How many yearly snapshots are kept upon cleanup
        };
      };
    };
    # calibre-web = {
    #   # Default admin credentials: admin, admin123
    #   enable = true;
    #   group = "shares";
    #   listen = {
    #     ip = "127.0.0.1";
    #     port = 8083;
    #   };
    #   openFirewall = false;
    #   options = {
    #     enableBookUploading = true;
    #     enableBookConversion = true;
    #     calibreLibrary = "/shares/books";
    #   };
    # };
    # copyparty = {
    #   enable = false;
    #   # directly maps to values in the [global] section of the copyparty config.
    #   # see `copyparty --help` for available options
    #   # Default port is 3923
    #   user = "copyparty";
    #   group = "shares";
    #   settings = {
    #     i = "127.0.0.1";
    #   };
    #   volumes = {
    #     "/" = {
    #       path = "/shares";
    #       access = {
    #         r = "*";
    #       };
    #     };
    #   };
    # };
    # caddy = {
    # # Caddy can automatically use tailscale certs for TLS on *.ts.net domains
    # # However only one cert can be used per machine
    #   enable = true;
    #   virtualHosts = {
    #     "srv1.snowy-ph.ts.net" = {
    #       listenAddresses = [
    #         "100.75.57.114"
    #         "127.0.0.1"
    #       ];
    #       serverAliases = [ "media.stelclementine.com" ];
    #       extraConfig = ''
    #         reverse_proxy 127.0.0.1:8096
    #       '';
    #     };
    #     "sync.stelclementine.com" = {
    #       listenAddresses = [
    #         "100.75.57.114"
    #       ];
    #       extraConfig = ''
    #         reverse_proxy 127.0.0.1:8384
    #       '';
    #     };
    #   };
    # };
    forgejo = {
      enable = true;
      useWizard = false;
      settings = {
        SERVER = {
          ROOT_URL = "http://git.stelclementine.com";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3022;
          DOMAIN = "git.stelclementine.com";
        };
      };
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        # "files.stelclementine.com" = {
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:3923";
        #   };
        #   listenAddresses = [
        #     "100.75.57.114"
        #     "127.0.0.1"
        #   ];
        #   extraConfig = ''
        #     proxy_redirect off;
        #     # disable buffering (next 4 lines)
        #     proxy_http_version 1.1;
        #     client_max_body_size 0;
        #     proxy_buffering off;
        #     proxy_request_buffering off;
        #     # improve download speed from 600 to 1500 MiB/s
        #     proxy_buffers 32 8k;
        #     proxy_buffer_size 16k;
        #
        #     access_log /var/log/nginx/copyparty.access.log;
        #   '';
        # };
        "media.stelclementine.com" = {
          default = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8096";
          };
          listenAddresses = [
            "100.75.57.114"
            "127.0.0.1"
          ];
        };
        # "books.stelclementine.com" = {
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:8083";
        #   };
        #   listenAddresses = [
        #     "100.75.57.114"
        #   ];
        # };
        "sync.stelclementine.com" = {
          # Syncthing GUI
          locations."/" = {
            proxyPass = "http://127.0.0.1:8384";
          };
          listenAddresses = [
            "100.75.57.114"
          ];
        };
        "git.stelclementine.com" = {
          # Forgejo
          locations."/" = {
            proxyPass = "http://127.0.0.1:3022";
          };
          listenAddresses = [
            "100.75.57.114"
          ];
        };
      };
    };
  };

  # Default umask is 0022 (man systemd.exec) which restricts group and other write access
  # Umask bits say: "what permissions are DENIED"
  # 0 (special bit is not affected)
  # 0 - 000 (no owning user permissions are denied)
  # 2 - 011 (group write and execute are denied)
  # 2 - 011 (others write and execute are denied)
  systemd.services = {
    # copyparty.serviceConfig.UMask = lib.mkForce "0007";
    # calibre-web.serviceConfig.UMask = lib.mkForce "0007";
    syncthing.serviceConfig.UMask = lib.mkForce "0007";
  };

  # security.acme = {
  #   acceptTerms = true;
  #   certs = {
  #     "fileparty.".email = config.admin.email;
  #   };
  # };

  # man tmpfiles.d
  # Special bits - the x in x770
  # 4 - setuid: This file when executed will inherit owner
  # 2 - setgid: This file when executed will inherit group OR new files inside this directory will inherit group
  # 1 - sticky: All files inside this directory can only be modified by owner (i.e. /tmp)
  systemd.tmpfiles.rules = [
    "d /srv/multimedia 2770 root multimedia -"
    "d /shares 2770 root shares -"
  ];

  # lsblk -o name,model,size,type,fstype,mountpoint,uuid
  # https://blog.pankajraghav.com/2024/09/17/AUTOMOUNT.html
  fileSystems."/shares/hdd" = {
    device = "/dev/disk/by-uuid/fabb5a38-c104-4e34-8652-04864df28799";
    fsType = "btrfs";
    options = [
      "defaults"
      "noatime"
      "x-systemd.automount"
      "x-systemd.device-timeout=5"
      "noauto"
    ];
  };

  # security.pam.pam-parallel = {
  #   enable = false;
  #   applyToModules = [
  #     "gtklock"
  #     "ly"
  #   ];
  #   methods = {
  #     fprint = {
  #       description = "Fingerprint";
  #       rule = "auth sufficient ${pkgs.fprintd}/lib/security/pam_fprintd.so";
  #     };
  #     password = {
  #       description = "Password";
  #       rule = "auth sufficient ${config.security.pam.package}/lib/security/pam_unix.so likeauth nullok try_first_pass";
  #     };
  #   };
  # };

  system.stateVersion = "24.11";

}

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  sshPublicKeys = (import ../../secrets/keys.nix);
in

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.nixos-generators.nixosModules.all-formats
    inputs.disko.nixosModules.disko
    ./nixpkgs.nix
    ./options.nix
    ../syncthing
    ../graphical
    ../battery
    ../audio
    ../bluetooth
    ../virtualisation
    ../pam-parallel
  ];

  config = {

    boot = {
      # NixOS uses latest LTS kernel by default: https://www.kernel.org/category/releases.html
      # kernelPackages = pkgs.linuxPackages_6_6;
      tmp.cleanOnBoot = !config.profile.virtual; # Only for physical machines
      tmp.useTmpfs = config.profile.virtual; # Technically better option but has weird implications on hibernation bc tmpfs occupies mem/swap
      loader = {
        grub.enable = config.profile.virtual;
        systemd-boot.enable = !config.profile.virtual;
        efi.canTouchEfiVariables = !config.profile.virtual;
      };
      initrd.systemd = {
        # For booting from hibernation with encrypted swap
        enable = !config.profile.virtual;
        # Root login shell if things go awry or if "emergency" is included in boot args
        emergencyAccess = true;
        services.cryptsetup-timeout = {
          # man systemd-cryptsetup@.service
          # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/system/boot/systemd/initrd.nix
          # https://blog.decent.id/post/nixos-systemd-initrd/
          # https://discourse.nixos.org/t/migrating-to-boot-initrd-systemd-and-debugging-stage-1-systemd-services/54444/7
          # As root: nix shell nixpkgs#dracut, lsinitrd /boot/EFI/nixos/...
          wantedBy = [ "sysinit.target" ];
          bindsTo = [ "systemd-cryptsetup@crypted.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "/bin/sh -c 'sleep 180 && systemctl poweroff'";
          };
        };
      };
    };

    networking = {
      # For resolved DoT resolving
      # https://github.com/curl/curl/wiki/DNS-over-HTTPS
      nameservers = [
        "76.76.2.11#p0.freedns.controld.com"
        "2606:1a40::11#p0.freedns.controld.com"
        "9.9.9.9#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
        # "116.202.176.26#dot.libredns.gr"
        # "81.169.136.222#ns3.opennameserver.org"
        # "185.181.61.24#ns4.opennameserver.org"
        # dnscry.pt and mullvlad are other options
      ];
      # Without NetworkManager, machine will still obtain IP address via DHCP
      networkmanager = {
        enable = !config.profile.virtual; # Only for physical machines
        dns = "systemd-resolved";
      };
    };

    systemd = {
      # DefaultLimitNOFILE= defaults to 1024:524288
      # Set limits for systemd units (not systemd itself).
      extraConfig = ''
        [Manager]
        DefaultTimeoutStopSec=10
        DefaultTimeoutAbortSec=10
        DefaultLimitNOFILE=8192:524288
      '';
      sleep.extraConfig = ''
        MemorySleepMode=deep s2idle
        HibernateDelaySec=1h
      '';
    };

    # Set your time zone.
    time.timeZone = lib.mkDefault "America/Los_Angeles";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    console = {
      useXkbConfig = true;
      colors = with config.theme.set; [
        bgx
        redx
        greenx
        yellowx
        bluex
        magentax
        cyanx
        fgx
        bg3x # for comments and autosuggestion to pop out
        redx
        greenx
        yellowx
        bluex
        magentax
        cyanx
        fgx
      ];
    };

    # security.sudo.enable = false;
    # security.acme.email = "sysadmin@stelclementine.com";
    # security.acme.acceptTerms = true;
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "8192"; # ulimit -n (default is 1024)
      }
    ];

    # If the host's system public key is in the key registry file, assume the core age secrets are available
    age.secrets = lib.mkIf (sshPublicKeys.systemKeys ? "${config.networking.hostName}") {
      admin-password.file = ../../secrets/admin-password.age;
    };

    users = {
      groups = {
        multimedia = { };
      };
      mutableUsers = false;
      users = {
        root =
          # Default password is "password" unless system ssh key is in the public key registry file
          # In that case the encrypted age password should be available, use that instead
          # Override with hashedPasswordFile (use mkpasswd)
          if (config.age.secrets ? admin-password) then
            {
              hashedPasswordFile = config.age.secrets.admin-password.path;
            }
          else
            {
              password = "password";
            };
        ${config.admin.username} =
          (
            if (config.age.secrets ? admin-password) then
              {
                hashedPasswordFile = config.age.secrets.admin-password.path;
              }
            else
              {
                password = "password";
              }
          )
          // {
            isNormalUser = true;
            # https://wiki.archlinux.org/title/Users_and_groups#Group_list
            extraGroups = [
              "networkmanager"
              "wheel"
              "tty"
              "dialout"
              "audio"
              "video"
              "cdrom"
              "multimedia"
              "libvirtd"
            ];
            openssh.authorizedKeys.keys = sshPublicKeys.allAdminKeys;
            shell = pkgs.zsh;
          };
      };
    };

    programs = {
      zsh.enable = true;
      starship = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ../../misc/starship.toml);
      };
      git.enable = true;
      nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 7d --keep 7";
        };
        flake = "/home/${config.admin.username}/.config/nixflake";
      };
    };

    environment = {
      systemPackages = [
        pkgs.vim
        pkgs.neovim
        pkgs.bat
        pkgs.fd
        pkgs.ripgrep
        pkgs.tealdeer
        pkgs.unzip
        pkgs.git
        pkgs.eza
        pkgs.curl
      ];
      pathsToLink = [ "/share/zsh" ];
    };

    services = {

      fwupd.enable = !config.profile.virtual;

      # Nice to have, required for gnome-disks to work
      udisks2.enable = true;

      logind = {
        lidSwitch = "ignore";
        powerKey = "sleep";
        powerKeyLongPress = "poweroff";
      };

      # https://dnscheck.tools/
      # Quad9 shows up as WoodyNet
      # https://wiki.archlinux.org/title/Systemd-resolved#DNS_over_TLS
      # Test with `ngrep port 53` and `ngrep port 883`
      resolved = {
        enable = true;
        dnsovertls = "true";
      };

      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

    };

    hardware.enableRedistributableFirmware = !config.profile.virtual;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs;
        systemConfig = config;
      };
      backupFileExtension = "backup";
      users.${config.admin.username} = {
        imports = [
          ./home.nix
          ../../hosts/${config.networking.hostName}/home.nix
        ];
        config = {
          inherit (config) activities profile theme;
        };
      };
    };

    virtualisation.vmVariant = {
      profile.virtualHost = lib.mkForce false;
      virtualisation = {
        memorySize = 4096;
        cores = 4;
      };
      boot.initrd.secrets = lib.mkForce { };
      services.syncthing.enable = lib.mkForce false;
      boot.initrd.luks.devices = lib.mkForce { };
      networking.wg-quick.interfaces = lib.mkForce { };
      users.users = {
        root.hashedPassword = lib.mkForce "$y$j9T$GAOQggBNWKTXXoCXQCGiw0$wVVmGFS2rI.9QDGe51MQHYcEr02FqHVJ1alHig9Y475";
        ${config.admin.username}.hashedPassword =
          lib.mkForce "$y$j9T$GAOQggBNWKTXXoCXQCGiw0$wVVmGFS2rI.9QDGe51MQHYcEr02FqHVJ1alHig9Y475";
      };
    };

    # I could do this to only create generations tied to specific commits but
    # then I couldn't rebuild from a dirty git repo.
    # system.nixos.label =
    #   let
    #     # Tag each generation with Git hash
    #     system.configurationRevision =
    #       if (inputs.self ? rev)
    #       then inputs.self.shortRev
    #       else throw "Refusing to build from a dirty Git tree!";
    #   in
    #   "GitRev.${config.system.configurationRevision}.Rel.${config.system.nixos.release}";

  };
}

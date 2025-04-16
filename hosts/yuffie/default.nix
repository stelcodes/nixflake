{ pkgs, lib, config, inputs, ... }: {

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

  services = {
    displayManager.ly = {
      enable = true;
      # https://github.com/fairyglade/ly/blob/master/res/config.ini
      settings = {
        animation = "matrix"; # doom matrix colormix
      };
    };
    xserver = {
      enable = true;
      autorun = true;
      desktopManager = {
        gnome.enable = true;
      };
    };
  };

  environment.gnome.excludePackages = (with pkgs; [
    # orca
    # evince
    # geary
    # gnome-disk-utility
    seahorse
    # sushi
    # gnome-shell-extensions
    # adwaita-icon-theme
    gnome-backgrounds
    # gnome-bluetooth
    # gnome-color-manager
    # gnome-control-center
    gnome-shell-extensions
    gnome-tour # GNOME Shell detects the .desktop file on first log-in.
    gnome-user-docs
    # gnome-menus
    # baobab
    epiphany
    gnome-text-editor
    gnome-calculator
    gnome-calendar
    gnome-characters
    # gnome-clocks
    gnome-console
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    # gnome-system-monitor
    gnome-weather
    # loupe
    # nautilus
    gnome-connections
    simple-scan
    snapshot
    totem
    yelp
    gnome-software
  ]);

  # Needed to create Rasp Pi SD images
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  networking = {
    firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  system.stateVersion = "24.11";

}

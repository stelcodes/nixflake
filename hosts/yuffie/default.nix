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
    atomix # puzzle game
    cheese # webcam tool
    epiphany # web browser
    evince # document viewer
    geary # email reader
    gedit # text editor
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori # sudoku game
    iagno # go game
    tali # poker game
    totem # video player
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

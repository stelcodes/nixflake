{ pkgs, inputs, config, lib, ... }: {


  config = lib.mkIf config.profile.graphical {

    # Supposedly not needed for xpadneo with newer kernels but on 6.6.7 this immediately fixed all issues so :shrug:
    boot.extraModprobeConfig = lib.mkIf config.activities.gaming "options bluetooth disable_ertm=1";

    hardware.graphics.enable = true;

    programs = {

      # Need this for font-manager or any other gtk app to work I guess
      dconf.enable = true;

      sway.enable = true;

      niri.enable = true;

      steam.enable = lib.mkIf config.activities.gaming true;

    };

    services = {

      # Enable CUPS to print documents.
      printing = {
        enable = false; # Security nightmare, only enable if necessary
        drivers = [
          pkgs.hplip
        ];
      };

      displayManager.ly = {
        enable = true;
        # https://github.com/fairyglade/ly/blob/master/res/config.ini
        settings = {
          animation = "matrix"; # Options: doom matrix colormix
          xinitrc = "null"; # Hides xinitrc session option
        };
      };

      # Set keyboard settings for raw linux terminal and ly
      # Implicitly enabled by having a desktop manager enabled: nixos/modules/services/misc/graphical-desktop.nix
      xserver.xkb = {
        layout = pkgs.lib.mkDefault "us";
        variant = pkgs.lib.mkDefault "";
        options = pkgs.lib.mkDefault "caps:escape_shifted_capslock,altwin:swap_alt_win";
      };

      libinput.enable = true;

      spice-vdagentd.enable = config.profile.virtualHost;
    };

    fonts = {
      fontconfig.enable = true;
      enableDefaultPackages = true;
      packages = [
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/fonts/nerdfonts/shas.nix
        pkgs.nerd-fonts.fira-mono
      ];
    };

    xdg = {
      portal = {
        enable = true;
        # gtkUsePortal = true;
        # xdgOpenUsePortal = true;
        # wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
        # https://github.com/emersion/xdg-desktop-portal-wlr?tab=readme-ov-file#running
        config.sway = {
          default = "gtk";
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr";
        };
      };
    };

    # xserver.desktopManager.gnome.enable = true;
    environment.gnome.excludePackages = (with pkgs; [
      seahorse
      gnome-backgrounds
      gnome-shell-extensions
      gnome-tour # GNOME Shell detects the .desktop file on first log-in.
      gnome-user-docs
      epiphany
      gnome-text-editor
      gnome-calendar
      gnome-characters
      gnome-console
      gnome-contacts
      gnome-maps
      gnome-music
      gnome-connections
      simple-scan
      snapshot
      totem
      yelp
      gnome-software
    ]);

  };
}

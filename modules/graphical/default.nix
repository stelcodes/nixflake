{ pkgs, inputs, config, lib, ... }: {

  config = lib.mkIf config.profile.graphical {

    # Supposedly not needed for xpadneo with newer kernels but on 6.6.7 this immediately fixed all issues so :shrug:
    boot.extraModprobeConfig = lib.mkIf config.activities.gaming "options bluetooth disable_ertm=1";

    hardware.graphics.enable = true;

    # As of 24.05 this is required to avoid having lightdm start automatically when services.xserver.enable = true
    systemd.services.display-manager.enable = config.services.xserver.autorun;

    programs = {

      # Need this for font-manager or any other gtk app to work I guess
      dconf.enable = true;

      sway.enable = true;

      steam.enable = lib.mkIf config.activities.gaming true;

    };

    services = {

      # Enable CUPS to print documents.
      printing = {
        enable = true;
        drivers = [
          pkgs.hplip
        ];
      };

      # Configure keymap in X11
      xserver = {
        enable = true;
        autorun = lib.mkDefault false;
        xkb = {
          layout = pkgs.lib.mkDefault "us";
          variant = pkgs.lib.mkDefault "";
          options = pkgs.lib.mkDefault "caps:escape_shifted_capslock,altwin:swap_alt_win";
        };
      };

      libinput.enable = true;

      gnome.gnome-keyring.enable = true;

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

  };
}

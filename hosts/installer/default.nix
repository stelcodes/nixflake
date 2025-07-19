{ pkgs, config, ... }:
{
  config = {
    profile = {
      graphical = false;
      battery = false;
      audio = false;
      bluetooth = false;
      virtualHost = false;
    };
    nixpkgs.config.allowUnfree = true; # For broadcom_sta
    environment.systemPackages = [
      pkgs.git
      pkgs.neovim
    ];
    boot = {
      kernelModules = [ "wl" ];
      extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    };
  };
}

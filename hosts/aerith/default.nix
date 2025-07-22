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
  };

  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  hardware.facetimehd = {
    enable = true;
    withCalibration = true;
  };

  system.stateVersion = "25.05";
}

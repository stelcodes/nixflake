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

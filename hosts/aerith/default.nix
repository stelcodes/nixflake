{ config, lib, ... }:
{

  imports = [
    ./hardware-configuration.nix
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

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Enable swap on luks
  boot.initrd.luks.devices."luks-aa91d73b-ad89-4d21-8221-0dcdd36b142a".device =
    "/dev/disk/by-uuid/aa91d73b-ad89-4d21-8221-0dcdd36b142a";

  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  hardware.facetimehd = {
    enable = true;
    withCalibration = true;
  };

  system.stateVersion = "23.11";
}

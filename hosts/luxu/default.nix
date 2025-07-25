{
  config,
  lib,
  modulesPath,
  ...
}:
{
  # NixOS Custom Installer
  # nix build \.#nixosConfigurations.luxu.config.formats.iso
  # nix shell nixpkgs#qemu
  # qemu-system-x86_64 -enable-kvm -m 8192 -cdrom ./result/iso/*.iso

  config = {

    profile = {
      graphical = true;
      battery = false;
      audio = true;
      bluetooth = true;
      physical = false;
      virtualHost = false;
    };

    admin.hashedPassword = "$y$jBT$V2cnjI9JtnryszC40nsSu1$X.f5ngktZoprbV.SLZnIyWb4BUZUhrj7CWHN7PANWgC";

    boot = {
      kernelModules = [
        "wl"
        "usbhid"
      ];
      extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    };

    time.timeZone = "America/Chicago";

    networking = {
      nameservers = lib.mkDefault [
        # Quad9
        "9.9.9.9"
        "2620:fe::9"
      ];
      networkmanager.enable = true;
    };

    services.resolved = {
      enable = true; # Enables networkmanager.dns automatically
      dnsovertls = "opportunistic";
    };

    hardware.enableRedistributableFirmware = true;

    system.stateVersion = "25.05";

  };

}

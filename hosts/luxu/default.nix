{
  config,
  modulesPath,
  ...
}:
{
  # NixOS Custom Installer
  # nix build \.#nixosConfigurations.luxu.config.formats.iso
  # nix shell nixpkgs#qemu
  # qemu-system-x86_64 -enable-kvm -m 8192 -cdrom ./result/iso/*.iso

  imports = [
    # For QEMU testing
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  config = {

    profile = {
      graphical = true;
      battery = false;
      audio = true;
      bluetooth = true;
      physical = false;
      virtualHost = false;
    };

    boot = {
      kernelModules = [ "wl" "usbhid" ];
      extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    };

    time.timeZone = "America/Chicago";

    networking.networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    hardware.enableRedistributableFirmware = true;

    system.stateVersion = "25.05";

  };

}

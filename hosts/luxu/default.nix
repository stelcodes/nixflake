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

  import = [
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
      kernelModules = [ "wl" ];
      extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    };

    system.stateVersion = "25.05";

  };

}

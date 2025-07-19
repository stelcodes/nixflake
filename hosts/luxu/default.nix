{
  lib,
  config,
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
      battery = true;
      audio = true;
      bluetooth = true;
      physical = false;
      virtualHost = false;
    };

    boot = {
      kernelModules = [ "wl" ];
      extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
      loader.systemd-boot.enable = lib.mkForce false;
      initrd.systemd.enable = lib.mkForce false;
      tmp.cleanOnBoot = lib.mkForce false;
    };

    services.openssh.settings = {
      # Allow logging into root via password for installation
      PasswordAuthentication = lib.mkForce true;
      PermitRootLogin = lib.mkForce "yes";
    };

    system.stateVersion = "25.05";

  };

}

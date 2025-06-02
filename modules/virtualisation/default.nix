{
  pkgs,
  lib,
  config,
  ...
}:
{

  config = lib.mkIf config.profile.virtualHost {

    environment.systemPackages = lib.lists.optionals config.profile.graphical [
      pkgs.virt-manager
      pkgs.virt-viewer
      pkgs.spice
      pkgs.spice-gtk
      pkgs.spice-protocol
      pkgs.win-virtio
      pkgs.win-spice
      pkgs.distrobox
    ];

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          ovmf.enable = true;
          ovmf.packages = [ pkgs.OVMFFull.fd ];
        };
      };
      podman.enable = true;
      spiceUSBRedirection.enable = true;
    };
  };

}

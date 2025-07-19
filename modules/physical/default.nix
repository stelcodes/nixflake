{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  config = lib.mkIf config.profile.physical {

    boot = {
      tmp.cleanOnBoot = true;
      tmp.useTmpfs = false; # Technically better option but has weird implications on hibernation bc tmpfs occupies mem/swap
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      initrd.systemd = {
        # For booting from hibernation with encrypted swap
        enable = true;
        # Root login shell if things go awry or if "emergency" is included in boot args
        emergencyAccess = true;
        services.cryptsetup-timeout = {
          # man systemd-cryptsetup@.service
          # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/system/boot/systemd/initrd.nix
          # https://blog.decent.id/post/nixos-systemd-initrd/
          # https://discourse.nixos.org/t/migrating-to-boot-initrd-systemd-and-debugging-stage-1-systemd-services/54444/7
          # As root: nix shell nixpkgs#dracut, lsinitrd /boot/EFI/nixos/...
          wantedBy = [ "sysinit.target" ];
          bindsTo = [ "systemd-cryptsetup@crypted.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "/bin/sh -c 'sleep 180 && systemctl poweroff'";
          };
        };
      };
    };

    systemd.sleep.extraConfig = ''
      MemorySleepMode=deep s2idle
      HibernateDelaySec=1h
    '';

    time.timeZone = lib.mkDefault "America/Chicago";

    networking.networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    hardware.enableRedistributableFirmware = true;

    services.fwupd.enable = true;

  };

}

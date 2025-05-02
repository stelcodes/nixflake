{ pkgs, lib, config, inputs, ... }: {

  imports = [
    # See https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  profile = {
    audio = true;
    bluetooth = true;
    graphical = true;
    battery = true;
    virtual = false;
    virtualHost = false;
  };

  activities = {
    coding = true;
    gaming = false;
    djing = false;
    jamming = false;
  };

  # Needed to create Rasp Pi SD images
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  services = {
    # https://bitsheriff.dev/posts/2025-01-05_how-to-use-the-fingerprint-reader-on-arch/
    # https://wiki.archlinux.org/title/Fprint
    # Use fprintd-enroll to register right index finger
    # When enabled, swaylock only accepts fingerprints https://github.com/swaywm/swaylock/issues/61
    fprintd.enable = true;
    jellyfin = {
      enable = true;
      group = "multimedia";
      openFirewall = false;
    };
  };

  security.wrappers = {
    # Necessary for burning CDs with k3b
    cdrdao = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrdao}/bin/cdrdao";
    };
    cdrecord = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrtools}/bin/cdrecord";
    };
  };

  # man tmpfiles.d
  # Special bits - the x in x770
  # 4 - setuid: This file when executed will inherit owner
  # 2 - setgid: This file when executed will inherit group OR new files inside this directory will inherit group
  # 1 - sticky: All files inside this directory can only be modified by owner (i.e. /tmp)
  systemd.tmpfiles.rules = [
    "d /srv/multimedia 2770 root multimedia -"
  ];

  security.pam.pam-parallel = {
    enable = true;
    applyToModules = [ "swaylock" "ly" ];
    methods = {
      fprint = {
        description = "Fingerprint";
        rule = "auth sufficient ${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
      password = {
        description = "Password";
        rule = "auth sufficient ${config.security.pam.package}/lib/security/pam_unix.so likeauth nullok try_first_pass";
      };
    };
  };

  system.stateVersion = "24.11";

}

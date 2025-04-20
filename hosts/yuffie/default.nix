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

  # man tmpfiles.d
  # Special bits - the x in x770
  # 4 - setuid: This file when executed will inherit owner
  # 2 - setgid: This file when executed will inherit group OR new files inside this directory will inherit group
  # 1 - sticky: All files inside this directory can only be modified by owner (i.e. /tmp)
  systemd.tmpfiles.rules = [
    "d /srv/multimedia 2770 root multimedia -"
  ];

  # Attempt to make pam-parallel work, but I can't figure it out
  # security.pam.services =
  #   let
  #     settings = builtins.toJSON
  #       {
  #         mode = "One";
  #         modules = { pam_fprintd = "Fingerprint"; login = "Password"; };
  #       };
  #     serviceCfg = service: {
  #       rules.auth = {
  #         pam-parallel = {
  #           order = config.security.pam.services.swaylock.rules.auth.fprintd.order - 10;
  #           control = "sufficient";
  #           modulePath = "${pkgs.pam-parallel}/lib/security/pam_parallel.so";
  #           args = [
  #             "debug"
  #             settings
  #           ];
  #         };
  #       };
  #     };
  #   in
  #   lib.flip lib.genAttrs serviceCfg [
  #     "sudo"
  #     "su"
  #     "swaylock"
  #     "ly"
  #     "login"
  #     "passwd"
  #   ];

  system.stateVersion = "24.11";

}

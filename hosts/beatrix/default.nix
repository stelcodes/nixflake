{
  pkgs,
  config,
  inputs,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
  ];

  system.stateVersion = "23.11";

  profile = {
    audio = true;
    battery = false;
    bluetooth = true;
    graphical = true;
    virtual = false;
    virtualHost = false;
  };

  activities.coding = true;

  hardware = {
    xpadneo.enable = true;
  };

  services = {

    samba = {
      # https://nixos.wiki/wiki/Samba
      # smbpasswd -a my_user
      enable = true;
      securityType = "user";
      openFirewall = true;
      extraConfig = # ini
        ''
          # Guests are disabled by default
          server string = smbnix
          netbios name = smbnix
          # Speed increase?
          use sendfile = yes
          hosts allow = 192.168.0. 192.168.1. 127.0.0.1 localhost marlene.local
          hosts deny = 0.0.0.0/0
        '';
      shares = {
        private = {
          # path = "/var/lib/samba/private";
          path = "/run/media/archive";
          browseable = "yes"; # default
          "read only" = "yes";
          "guest ok" = "no"; # default
          "create mask" = "0644";
          "directory mask" = "0755"; # default
          "force user" = "stel";
          "force group" = "users";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    nfs.server = {
      # Don't forget to open firewall
      # allowedTCPPorts = [ 2049 ];
      # allowedUDPPorts = [ 2049 ];
      enable = true;
      # https://www.man7.org/linux/man-pages/man5/exports.5.html
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
      exports = ''
        /nfs 192.168.1.101(rw,fsid=root,no_subtree_check) 192.168.1.102(rw,fsid=root,no_subtree_check)
        /nfs/archive 192.168.1.101(rw,nohide,no_subtree_check,all_squash,anonuid=1000,anongid=1000) 192.168.1.102(rw,nohide,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
      '';
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        111
        2049
        4000
        4001
        4002
      ];
      allowedUDPPorts = [
        111
        2049
        4000
        4001
        4002
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /nfs 0755 root root -"
    "d /jellyfin 0755 jellyfin jellyfin -"
  ];

  fileSystems = {
    "/jellyfin" = {
      device = "/run/media/archive/videos";
      options = [
        "ro"
        "bind"
        "nofail"
        "noatime"
      ];
    };
    "/nfs/archive" = {
      device = "/run/media/archive";
      options = [
        "bind"
        "nofail"
        "noatime"
      ];
    };
    "/run/media/archive" = {
      device = "/dev/disk/by-uuid/fabb5a38-c104-4e34-8652-04864df28799";
      fsType = "btrfs";
      options = [
        "nofail"
        "noatime"
      ];
    };
  };

}

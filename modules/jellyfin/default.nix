{
  pkgs,
  config,
  lib,
  ...
}:
{
  config = {
    virtualisation.oci-containers.containers."jellyfin" = {
      autoStart = true;
      image = "jellyfin/jellyfin";
      volumes = [
        # "/some/path/containers/jellyfin/config:/config"
        # "/some/path/containers/jellyfin/cache:/cache"
        # "/some/path/containers/jellyfin/log:/log"
        # "/some/path/videos/movies:/movies:ro"
        # "/some/path/videos/shows:/shows:ro"
      ];
      ports = [
        "8096:8096"
        "8920:8920"
        "1900:1900"
        "7359:7359"
      ];
      environment = {
        JELLYFIN_LOG_DIR = "/log";
      };
    };
    networking = {
      firewall = {
        enable = true;
        allowedTCPPorts = [
          8096
          8920
        ];
        allowedUDPPorts = [
          1900
          7359
        ];
      };
    };

  };
}

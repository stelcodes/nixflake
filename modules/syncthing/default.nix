{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.syncthing;
  dataDir = "/home/${config.admin.username}/sync";
  secretKey = "sync4life";
  # https://docs.syncthing.net/users/versioning
  # cleanupIntervalS must be int, params must be strings
  # Debug with journalctl -exf --unit syncthing-init.service
  staggeredMonth = {
    type = "staggered";
    cleanupIntervalS = 86400; # Once every day
    params = {
      maxAge = "2592000"; # Keep versions for up to a month
    };
  };
  trashcanBasic = {
    type = "trashcan";
    cleanupIntervalS = 86400; # Once every day
    params = {
      cleanoutDays = "7";
    };
  };
  devices = {
    yuffie = {
      autoAcceptFolders = true;
      id = "G5Q3Q2S-6UCPWME-FPX4RSD-3AWNHAV-36BCGNE-HQ6NEV2-2LWC2MA-DUVQDQZ";
    };
    aerith = {
      autoAcceptFolders = true;
      id = "JUABVAR-HLJXGIQ-4OZHN2G-P3WJ64R-D77NR74-SOIIEEC-IL53S4S-BO6R7QE";
    };
    beatrix = {
      autoAcceptFolders = true;
      id = "ZZTXMYW-7FC4BBY-4QHAB6R-2RCMQDT-SRTS3F7-ZZSL4WE-27P4Y46-5YC4CAZ";
    };
    celes = {
      autoAcceptFolders = true;
      id = "2N6LGUP-2YKWX3Z-J2YPY5N-GUS34IL-HKDNOGM-CHWD6EG-6ODSB5F-2GV4GQ7";
    };
    marlene = {
      autoAcceptFolders = true;
      id = "5PLUKOY-HRDBENY-LSS2MYZ-36CCNA6-SBTAWXS-RAY2Q4X-5NAGEBI-X6QRJA6";
    };
  };
  folders = {
    default = {
      versioning = trashcanBasic;
      path = "${dataDir}/default";
      devices = builtins.attrNames devices;
    };
    games = {
      versioning = staggeredMonth;
      path = "${dataDir}/games";
      devices = [ "beatrix" ];
    };
    notes = {
      versioning = staggeredMonth;
      path = "${dataDir}/notes";
      devices = [
        "beatrix"
        "celes"
        "yuffie"
        "aerith"
        "marlene"
      ];
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    users.users.${config.admin.username}.packages = [ pkgs.syncthing ];
    services = {
      syncthing = {
        inherit dataDir;
        openDefaultPorts = true;
        user = config.admin.username;
        configDir = "/home/${config.admin.username}/.config/syncthing";
        guiAddress = "127.0.0.1:8384";
        settings = {
          inherit devices;
          folders = (lib.filterAttrs (key: value: lib.elem config.networking.hostName value.devices) folders);
          options = {
            # urSeen and urAccepted don't seem to stop the popup but they are absolutely the right settings
            urSeen = 3;
            urAccepted = -1;
          };
          gui = {
            user = config.admin.username;
            password = secretKey;
            apikey = secretKey;
          };
          defaults.folder.path = "~/sync";
        };
      };
    };
  };
}

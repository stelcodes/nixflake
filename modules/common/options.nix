{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    profile = {
      graphical = lib.mkOption {
        type = lib.types.bool;
      };
      battery = lib.mkOption {
        type = lib.types.bool;
      };
      physical = lib.mkOption {
        type = lib.types.bool;
      };
      virtualHost = lib.mkOption {
        type = lib.types.bool;
      };
      audio = lib.mkOption {
        type = lib.types.bool;
      };
      bluetooth = lib.mkOption {
        type = lib.types.bool;
      };
    };
    activities = {
      gaming = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      coding = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      djing = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      jamming = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
    admin = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
      };
      hashedPassword = lib.mkOption {
        type = lib.types.str;
        default = "$y$jBT$3MSGh9jYkXFUBYaw33l2y0$anHuJV52z5nFur1hfvfGcTgOObxze97UVlF4M4UWJb/";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "sysadmin@stelclementine.com";
      };
    };
    theme.name = lib.mkOption {
      type = lib.types.str;
      default = "everforest";
    };
    theme.set = lib.mkOption {
      type = lib.types.attrs;
      default = (import ../../misc/themes.nix pkgs).${config.theme.name};
    };
  };
}

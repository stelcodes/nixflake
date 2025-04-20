{ config, pkgs, lib, ... }:
let
  cfg = config.security.pam.pam-parallel;
in
{
  options = {
    security.pam.pam-parallel = {
      enable = lib.mkEnableOption "Enable pam-parallel as a PAM authentication provider";
      order = lib.mkOption {
        type = lib.types.int;
        default = 1000;
      };
      applyToModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "One";
      };
      methods = lib.mkOption {
        type = lib.attrsOf (lib.types.submodule
          {
            description = lib.mkOption {
              type = lib.types.str;
            };
            rule = lib.mkOption {
              type = lib.types.str;
            };
          }
        );
        default = { };
      };
    };

  };
  config = lib.mkIf cfg.enable {
    security.pam.services =
      let
        jsonSettings = builtins.toJSON {
          mode = cfg.mode;
          modules = lib.mapAttrs'
            (methodName: methodValue: (lib.nameValuePair "${methodName}_parallel" methodValue.description))
            cfg.methods;
        };
        serviceCfg = service: {
          rules.auth.pam-parallel = {
            order = cfg.order;
            control = "sufficient";
            modulePath = "${pkgs.pam-parallel}/lib/security/pam_parallel.so";
            args = [ jsonSettings ];
          };
        };
      in
      (lib.flip lib.genAttrs serviceCfg cfg.applyToModules);

    environment.etc = lib.mapAttrs'
      (methodName: methodValue: lib.nameValuePair
        "pam.d/${methodName}_parallel"
        {
          source = pkgs.writeText "${methodName}_parallel.pam" methodValue.rule;
        })
      cfg.methods;
  };

}

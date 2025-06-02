{
  config,
  pkgs,
  lib,
  ...
}:
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
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              description = lib.mkOption {
                type = lib.types.str;
              };
              rule = lib.mkOption {
                type = lib.types.str;
              };
            };
          }
        );
        default = { };
        example = lib.literalExample ''
          {
            fprint = {
              description = "Fingerprint";
              rule = "auth sufficient ''${pkgs.fprintd}/lib/security/pam_fprintd.so";
            };
            password = {
              description = "Password";
              rule = "auth sufficient ''${config.security.pam.package}/lib/security/pam_unix.so likeauth nullok try_first_pass";
            };
          }
        '';
      };
    };

  };
  config = lib.mkIf cfg.enable {
    security.pam.services =
      let
        jsonSettings = builtins.toJSON {
          mode = cfg.mode;
          modules = lib.mapAttrs' (
            methodName: methodValue: (lib.nameValuePair "${methodName}_parallel" methodValue.description)
          ) cfg.methods;
        };
        serviceCfg = service: {
          rules.auth.pam-parallel = {
            order = cfg.order;
            control = "sufficient";
            modulePath = "${pkgs.pam-parallel}/lib/security/pam_parallel.so";
            args = [
              "debug"
              jsonSettings
            ];
          };
        };
      in
      (lib.flip lib.genAttrs serviceCfg cfg.applyToModules);

    environment.etc = lib.mapAttrs' (
      methodName: methodValue:
      lib.nameValuePair "pam.d/${methodName}_parallel" {
        source = pkgs.writeText "${methodName}_parallel.pam" methodValue.rule;
      }
    ) cfg.methods;
  };

}

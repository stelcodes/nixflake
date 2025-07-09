{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.services.postgresql;
in
{
  options = {
    services.postgresql = {
      basicSetup = {
        enable = lib.mkEnableOption "Setup basic local auth and admin user privileges";
        extraInitialScript = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
  };
  config = lib.mkIf cfg.basicSetup.enable {
    services.postgresql = {
      # https://nixos.wiki/wiki/PostgreSQL
      # https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
      # *Without a "local" record, Unix-domain socket connections are disallowed
      # *TCP/IP is less performant and less secure
      # local: matches connection attempts using Unix-domain sockets
      # sameuser: matches if the requested database has the same name as the requested user
      # all: matches for all DB users
      # peer: Obtain unix username from the kernel ("local" only)
      # map: Use this mapping for unix users -> DB users
      # https://www.postgresql.org/docs/current/auth-peer.html
      authentication = lib.mkOverride 10 ''
        #Type Database  DBUser  Method  Options
        ###############################################
        local sameuser  all     peer    map=user_map
        # Let admin log into any database (readonly due to pg_read_all_data role)
        local all ${config.admin.username} peer
      '';
      # User Name Maps: https://www.postgresql.org/docs/current/auth-username-maps.html
      # "___ operating system user is allowed to connect as ___ database user"
      identMap = ''
        # MapName     SystemUser    DBUser
        ###############################################
        # Let root and postgres log in as superuser
        user_map      root          postgres
        user_map      postgres      postgres
        # Let other users login as themselves
        user_map      /^(.*)$       \1
      '';
      # Create a toy database for the admin user
      ensureDatabases = [ config.admin.username ];
      # https://www.postgresql.org/docs/current/sql-createrole.html
      ensureUsers = [
        {
          # DB for admin experiments
          name = config.admin.username;
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
          };
        }
      ];
      # https://www.postgresql.org/docs/current/predefined-roles.html
      initialScript = pkgs.writeText "init-postgresql-script" (
        ''
          # Let admin user read all data
          GRANT pg_read_all_data TO ${config.admin.username};
        ''
        + (lib.concatStringsSep "\n" cfg.basicSetup.extraInitialScript)
      );
      # psql cheatsheet: https://tomcam.github.io/postgres/
      # \l list databases
      # \c connect to database
      # \d list tables, views, and sequences
      # \d NAME describe table, view, sequence, or index
    };
  };
}

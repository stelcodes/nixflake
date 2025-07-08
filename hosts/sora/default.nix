{
  lib,
  pkgs,
  config,
  ...
}:
{

  imports = [
    ./hardware.nix
    ./disks.nix
  ];

  config = {

    profile = {
      audio = false;
      bluetooth = false;
      graphical = false;
      battery = false;
      virtual = true;
      virtualHost = false;
    };

    # boot.kernel.sysctl = { "vm.swappiness" = 10; };
    # zramSwap.enable = true;

    services = {
      caddy = {
        enable = true;
      };
      postgresql = {
        # https://nixos.wiki/wiki/PostgreSQL
        enable = true;
        # By default, access DB through a "local" Unix socket
        # "/var/lib/postgresql" (TCP/IP is disabled by default because it's
        # less performant and less secure).
        # "root" and "postgres" system users can log in as "postgres" superuser
        # root$ psql -U postgres
        identMap = ''
          # ArbitraryMapName systemUser DBUser
          superuser_map      root       postgres
          superuser_map      postgres   postgres
          superuser_map         readonly
          # Let other names login as themselves
          superuser_map      /^(.*)$    \1
        '';
        # With "sameuser" Postgres will allow DB user access only to databases
        # of the same name. E.g. DB user "mydatabase" will get access to
        # database "mydatabase" and nothing else. The part map=superuser_map is
        # optional. One exception is the DB user "postgres", which by default
        # is a superuser/admin with access to everything.
        authentication = lib.mkOverride 10 ''
          #type database  DBuser  auth-method optional_ident_map
          local sameuser  all     peer        map=superuser_map
        '';
        ensureUsers = [
          {
            name = config.admin.username;
            ensureDBOwnership = true;
            login = true;
          }
        ];
        # https://www.postgresql.org/docs/current/sql-createrole.html
        # https://www.postgresql.org/docs/current/predefined-roles.html
        initialScript = pkgs.writeText "init-postgresql-script" ''
          GRANT pg_read_all_data TO ${config.admin.username};
        '';
      };
    };

    system.stateVersion = "25.05";

  };
}

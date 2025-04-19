{ pkgs, lib, config, ... }: {

  config = lib.mkIf config.profile.battery {

    powerManagement = {
      enable = lib.mkDefault true;
    };

    services = {
      upower = {
        enable = true;
        noPollBatteries = true;
        percentageCritical = 10;
        percentageAction = 5;
        criticalPowerAction = "HybridSleep";
      };
      tlp = {
        enable = true;
        settings = {
          MEM_SLEEP_ON_BAT = "deep";
          MEM_SLEEP_ON_AC = "deep";
        };
      };
    };

    systemd = {
      # Hibernate after 1 hour of sleep instead of waiting til battery runs out
      sleep.extraConfig = ''
        HibernateDelaySec=1h
        SuspendEstimationSec=1h
      '';

    };

  };

}

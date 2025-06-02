{
  pkgs,
  lib,
  config,
  ...
}:
{

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
          # Prevent clicks: https://linrunner.de/tlp/faq/audio.html
          SOUND_POWER_SAVE_ON_AC = 0;
          SOUND_POWER_SAVE_ON_BAT = 0;
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

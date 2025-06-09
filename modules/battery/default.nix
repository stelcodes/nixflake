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
          SOUND_POWER_SAVE_ON_AC = 300;
          SOUND_POWER_SAVE_ON_BAT = 300;
          # Reduce power usage: https://linrunner.de/tlp/support/optimizing.html
          CPU_ENERGY_PERF_POLICY_ON_AC = "power";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_BOOST_ON_AC = 0;
          CPU_BOOST_ON_BAT = 0;
          CPU_HWP_DYN_BOOST_ON_AC = 0;
          CPU_HWP_DYN_BOOST_ON_BAT = 0;
          WIFI_PWR_ON_AC = "on";
          WIFI_PWR_ON_BAT = "on";
          PLATFORM_PROFILE_ON_AC = "low-power";
          PLATFORM_PROFILE_ON_BAT = "low-power";
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

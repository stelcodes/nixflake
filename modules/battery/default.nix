{
  pkgs,
  lib,
  config,
  ...
}:
{

  config = lib.mkIf config.profile.battery {

    environment.systemPackages = [ pkgs.powertop ];

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
          CPU_ENERGY_PERF_POLICY_ON_AC = "default";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          PLATFORM_PROFILE_ON_AC = "balanced";
          PLATFORM_PROFILE_ON_BAT = "low-power";
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          CPU_HWP_DYN_BOOST_ON_AC = 1;
          CPU_HWP_DYN_BOOST_ON_BAT = 0;
          WIFI_PWR_ON_AC = "on";
          WIFI_PWR_ON_BAT = "on";
          # https://linrunner.de/tlp/settings/runtimepm.html#runtime-pm-on-ac-bat
          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";
          PCIE_ASPM_ON_AC = "powersave";
          PCIE_ASPM_ON_BAT = "powersave";
          # https://linrunner.de/tlp/settings/usb.html
          USB_AUTOSUSPEND = 1;
          USB_EXCLUDE_AUDIO = 0;
          USB_ALLOWLIST = "32ac:0002"; # Framwork USB HDMI Expansion Card
          # https://linrunner.de/tlp/settings/radio.html
          DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
          DEVICES_TO_ENABLE_ON_AC = "bluetooth";
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

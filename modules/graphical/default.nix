{ pkgs, inputs, config, lib, ... }: {

  config = lib.mkIf config.profile.graphical {

    # Supposedly not needed for xpadneo with newer kernels but on 6.6.7 this immediately fixed all issues so :shrug:
    boot.extraModprobeConfig = lib.mkIf config.activities.gaming "options bluetooth disable_ertm=1";

    hardware.graphics.enable = true;

    security.polkit = {
      debug = true;
      extraConfig = /* javascript */ ''
        // Log authorization checks
        polkit.addRule(function(action, subject) {
         polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
        });
        // Allow rebuilds for admin user without password
        polkit.addRule(function(action, subject) {
          polkit.log("action=" + action);
          polkit.log("subject=" + subject);
          var wheel = subject.isInGroup("wheel");
          var systemd = (action.id == "org.freedesktop.systemd1.manage-unit-files");
          var rebuild = (action.lookup("unit") == "nixos-rebuild.service");
          var verb = action.lookup("verb");
          var acceptedVerb = (verb == "start" || verb == "stop" || verb == "restart");
          if (wheel && systemd && rebuild && acceptedVerb) {
            return polkit.Result.YES;
          }
        });
      '';
    };

    # As of 24.05 this is required to avoid having lightdm start automatically when services.xserver.enable = true
    systemd.services.display-manager.enable = config.services.xserver.autorun;

    programs = {

      # Need this for font-manager or any other gtk app to work I guess
      dconf.enable = true;

      sway.enable = true;

      steam.enable = lib.mkIf config.activities.gaming true;

      firefox = {
        enable = true;
        # https://mozilla.github.io/policy-templates/
        # Apparently Mozilla doesn't let you set the default search engine using policies anymore >:c
        policies = {
          Preferences =
            let
              user = (x: { Status = "user"; Value = x; });
              locked = (x: { Status = "locked"; Value = x; });
            in
            {
              "browser.chrome.toolbar_tips" = locked false;
              "browser.uidensity" = locked 1;
              "browser.fullscreen.autohide" = locked false;
              "browser.tabs.insertAfterCurrent" = locked true;
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = locked false;
              "browser.urlbar.suggest.quicksuggest.sponsored" = locked false;
              "browser.urlbar.suggest.topsites" = locked false;
              "browser.urlbar.suggest.calculator" = locked true;
              "browser.urlbar.suggest.engines" = locked false;
              "browser.urlbar.suggest.searches" = locked false;
              # It looks like firefox doesn't allow font settings to be overridden
              "font.name.monospace.x-western" = locked "FiraMono Nerd Font";
              "font.size.monospace.x-western" = locked 16;
              "media.ffmpeg.vaapi.enabled" = locked true;
            };
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableSetDesktopBackground = true;
          DisableTelemetry = true;
          DisplayBookmarksToolbar = "newtab";
          DontCheckDefaultBrowser = true;
          DNSOverHTTPS = {
            Enabled = true;
            Locked = true;
          };
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
            Exceptions = [ ];
          };
          ExtensionSettings = {
            # https://github.com/mkaply/queryamoid/releases/tag/v0.1
            "queryamoid@kaply.com" = {
              installation_mode = "normal_installed";
              install_url = "https://github.com/mkaply/queryamoid/releases/download/v0.2/query_amo_addon_id-0.2-fx.xpi";
            };
            "uBlock0@raymondhill.net" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            };
            "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
            };
            "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/noscript/latest.xpi";
            };
            "myallychou@gmail.com" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
            };
            "{9063c2e9-e07c-4c2c-9646-cfe7ca8d0498}" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/old-reddit-redirect/latest.xpi";
            };
            "@testpilot-containers" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
            };
          };
          HardwareAcceleration = true;
          Homepage = {
            URL = "chrome://browser/content/blanktab.html";
            Locked = false;
            StartPage = "none";
          };
          # HttpsOnlyMode = "enabled";
          ManagedBookmarks = [
            { toplevel_name = "NixOS"; }
            { name = "Printing"; url = "https://localhost:631"; }
            { name = "Syncthing"; url = "https://localhost:8384"; }
            { name = "Jellyfin"; url = "https://macmini:8096"; }
            { name = "Firefox Policies"; url = "https://mozilla.github.io/policy-templates"; }
            { name = "Coding Radio"; url = "https://coderadio.freecodecamp.org"; }
          ];
          ManualAppUpdateOnly = true;
          NewTabPage = false;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          OverrideFirstRunPage = "";
          PasswordManagerEnabled = false;
          Permissions = {
            Notifications = {
              BlockNewRequests = true;
              Locked = true;
            };
          };
          WebsiteFilter = {
            Block = [
              "*://news.ycombinator.com/*"
            ];
            Exceptions = [ ];
          };
        };
      };

      chromium = {
        enable = true; # only enables polices to be put in etc, doesn't install chromium
        extensions = [
          "gighmmpiobklfepjocnamgkkbiglidom" # adblock
        ];
        # MANUAL SETTINGS:
        # chrome://settings/appearance
        #   Enable 'Use GTK'
        #   Enable 'Use system title bar and borders'
        # chrome://settings/syncSetup
        #   Disable 'Make searches and browsing better'
        # chrome://settings/searchEngines
        #   Enable DuckDuckGo default browser
        extraOpts = {
          AdvancedProtectionAllowed = false;
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          BackgroundModeEnabled = false;
          BatterySaverModeAvailability = 2;
          BlockThirdPartyCookies = true;
          BrowserNetworkTimeQueriesEnabled = false;
          BrowserSignin = 0;
          DefaultBrowserSettingEnabled = false;
          DefaultClipboardSetting = 2;
          DefaultFileSystemReadGuardSetting = 2;
          DefaultFileSystemWriteGuardSetting = 2;
          DefaultGeolocationSetting = 2;
          DefaultLocalFontsSetting = 2;
          DefaultNotificationsSetting = 2;
          DefaultPopupsSetting = 2;
          # DefaultSearchProviderEnabled = true;
          # DefaultSearchProviderName = "DuckDuckGo";
          # DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
          DefaultSensorsSetting = 2;
          DefaultSerialGuardSetting = 2;
          DefaultThirdPartyStoragePartitioningSetting = 2;
          # DefaultWebBluetoothGuardSetting = 2;
          # DefaultWebHidGuardSetting = 2;
          # DefaultWebUsbGuardSetting = 2;
          DefaultWindowManagementSetting = 2;
          DNSInterceptionChecksEnabled = false;
          DnsOverHttpsMode = "automatic";
          EnableMediaRouter = false;
          EnterpriseRealTimeUrlCheckMode = 0;
          HardwareAccelerationModeEnabled = true;
          HighEfficiencyModeEnabled = true;
          # HttpsOnlyMode = "force_enabled";
          HomepageIsNewTabPage = true;
          MediaRecommendationsEnabled = false;
          MetricsReportingEnabled = false;
          NTPCardsVisible = false;
          NTPCustomBackgroundEnabled = true;
          PasswordLeakDetectionEnabled = false;
          PasswordManagerEnabled = false;
          PromotionalTabsEnabled = false;
          PaymentMethodQueryEnabled = false;
          SafeBrowsingProtectionLevel = 0;
          ScreenCaptureAllowed = false;
          SearchSuggestEnabled = false;
          ShoppingListEnabled = false;
          SpellcheckEnabled = false;
          SyncDisabled = true;
          # https://chromeenterprise.google/policies/#URLBlocklist
          UserAgentReduction = 2;
        };
      };
    };

    services = {

      # Enable CUPS to print documents.
      printing = {
        enable = true;
        drivers = [
          pkgs.hplip
        ];
      };

      # Configure keymap in X11
      xserver = {
        enable = true;
        autorun = lib.mkDefault false;
        xkb = {
          layout = pkgs.lib.mkDefault "us";
          variant = pkgs.lib.mkDefault "";
          options = pkgs.lib.mkDefault "caps:escape_shifted_capslock,altwin:swap_alt_win";
        };
      };

      libinput.enable = true;

      gnome.gnome-keyring.enable = true;

      spice-vdagentd.enable = config.profile.virtualHost;
    };

    fonts = {
      fontconfig.enable = true;
      enableDefaultPackages = true;
      packages = [
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/fonts/nerdfonts/shas.nix
        pkgs.nerd-fonts.fira-mono
      ];
    };

    xdg = {
      portal = {
        enable = true;
        # gtkUsePortal = true;
        # xdgOpenUsePortal = true;
        # wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
        # https://github.com/emersion/xdg-desktop-portal-wlr?tab=readme-ov-file#running
        config.sway = {
          default = "gtk";
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr";
        };
      };
    };

  };
}

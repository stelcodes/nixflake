{
  pkgs,
  config,
  lib,
  ...
}:
{

  config = lib.mkIf config.profile.graphical {

    # Supposedly not needed for xpadneo with newer kernels but on 6.6.7 this immediately fixed all issues so :shrug:
    boot.extraModprobeConfig = lib.mkIf config.activities.gaming "options bluetooth disable_ertm=1";

    hardware.graphics.enable = true;

    programs = {

      # Need this for font-manager or any other gtk app to work I guess
      dconf.enable = true;

      sway = {
        enable = lib.mkDefault true;
        extraPackages = [ ];
      };

      niri.enable = lib.mkDefault true;

      gtklock = {
        enable = true;
        modules = [
          pkgs.gtklock-powerbar-module
        ];
      };

      chromium = {
        # This only creates the default policies JSON file, doesn't install chromium
        enable = false;
        extraOpts = {
          AdvancedProtectionAllowed = false;
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          BackgroundModeEnabled = false;
          BlockThirdPartyCookies = true;
          BrowserNetworkTimeQueriesEnabled = false;
          BrowserSignin = 0;
          DefaultBrowserSettingEnabled = false;
          DefaultSearchProvider = true;
          DefaultSearchProviderName = "DuckDuckGo";
          DefaultSearchProviderNewTabURL = "https://duckduckgo.com";
          DNSInterceptionChecksEnabled = false;
          BuiltInDnsClientEnabled = false; # Defer to system DNS
          EnableMediaRouter = true; # Google cast
          HardwareAccelerationModeEnabled = true;
          HighEfficiencyModeEnabled = true;
          HttpsOnlyMode = "force_balanced_enabled"; # Allow user to select http
          HomepageIsNewTabPage = true;
          MediaRecommendationsEnabled = false;
          MetricsReportingEnabled = false;
          PasswordLeakDetectionEnabled = false;
          PasswordManagerEnabled = false;
          PromotionalTabsEnabled = false;
          PaymentMethodQueryEnabled = false;
          SafeBrowsingProtectionLevel = 0;
          SearchSuggestEnabled = false;
          ShoppingListEnabled = false;
          SpellcheckEnabled = false;
          SyncDisabled = true;
        };
        # ungoogled-chromium needs this for extensions:
        # https://github.com/NeverDecaf/chromium-web-store
        # Flags cannot be set automatically:
        # chrome://flags/#disable-top-sites
        # chrome://flags/#extension-mime-request-handling
      };

    };

    services = {

      # Enable CUPS to print documents.
      printing = {
        enable = lib.mkDefault false; # Security nightmare, only enable if necessary
        drivers = [
          pkgs.hplip
        ];
      };

      displayManager.ly = {
        enable = true;
        # https://github.com/fairyglade/ly/blob/master/res/config.ini
        settings = {
          animation = "matrix"; # Options: doom matrix colormix
          xinitrc = "null"; # Hides xinitrc session option
        };
      };

      # Set keyboard settings for raw linux terminal and ly
      # Implicitly enabled by having a desktop manager enabled: nixos/modules/services/misc/graphical-desktop.nix
      xserver.xkb = {
        layout = pkgs.lib.mkDefault "us";
        variant = pkgs.lib.mkDefault "";
        options = pkgs.lib.mkDefault "caps:escape_shifted_capslock,altwin:swap_alt_win";
      };

      libinput.enable = true;

      spice-vdagentd.enable = config.profile.virtualHost;
    };

    fonts = {
      enableDefaultPackages = true;
      packages = [
        pkgs.nerd-fonts.fira-mono
        pkgs.joypixels # The only emoji font that works in kitty atm
      ];
      fontconfig = {
        enable = true;
        defaultFonts.emoji = [ "JoyPixels" ];
      };
    };

    environment.variables = {
      # https://github.com/thomX75/nixos-modules/tree/main/Glib-Schemas-Fix
      GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas";
    };

  };
}

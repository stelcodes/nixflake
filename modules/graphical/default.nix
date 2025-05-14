{ pkgs, inputs, config, lib, ... }: {


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
          EnableMediaRouter = false; # Google cast
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
      fontconfig.enable = true;
      enableDefaultPackages = true;
      packages = [
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/fonts/nerdfonts/shas.nix
        pkgs.nerd-fonts.fira-mono
      ];
    };

    # xserver.desktopManager.gnome.enable = true;
    environment.gnome.excludePackages = (with pkgs; [
      seahorse
      gnome-backgrounds
      gnome-shell-extensions
      gnome-tour # GNOME Shell detects the .desktop file on first log-in.
      gnome-user-docs
      epiphany
      gnome-text-editor
      gnome-calendar
      gnome-characters
      gnome-console
      gnome-contacts
      gnome-maps
      gnome-music
      gnome-connections
      simple-scan
      snapshot
      totem
      yelp
      gnome-software
    ]);

  };
}

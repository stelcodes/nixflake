{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  sshPublicKeys = (import ../../secrets/keys.nix);
in

{
  imports = [
    ./nixpkgs.nix
    ./options.nix
  ];

  config = {

    boot = {
      # NixOS uses latest LTS kernel by default: https://www.kernel.org/category/releases.html
      # kernelPackages = pkgs.linuxPackages_6_6;
      tmp.useTmpfs = lib.mkDefault true;
    };

    # Without NetworkManager, machine will still obtain IP address via DHCP

    # DefaultLimitNOFILE= defaults to 1024:524288
    # Set limits for systemd units (not systemd itself).
    systemd.settings.Manager = {
      DefaultTimeoutStopSec = 10;
      DefaultTimeoutAbortSec = 10;
      DefaultLimitNOFILE = "8192:524288";
    };

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    console = {
      useXkbConfig = true;
      colors = with config.theme.set; [
        bgx
        redx
        greenx
        yellowx
        bluex
        magentax
        cyanx
        fgx
        bg3x # for comments and autosuggestion to pop out
        redx
        greenx
        yellowx
        bluex
        magentax
        cyanx
        fgx
      ];
    };

    # security.sudo.enable = false;
    # security.acme.email = "sysadmin@stelclementine.com";
    # security.acme.acceptTerms = true;
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "8192"; # ulimit -n (default is 1024)
      }
    ];

    # It's *way* simpler to provision new machines when admin password isn't encrypted with agenix
    # Also using agenix for the admin password risks a lockout if secrets weren't rekeyed
    # The yescrypt algo is used by default in NixOS but it can be strengthened
    # A yescrypt hash format looks like this $y$<cost>$<salt>$<hash>
    # https://unix.stackexchange.com/a/724514
    # The rounds are derived by 2^(cost)
    # Default cost is 5 (2^5 = 32 rounds), and should be between 3 and 11
    # https://github.com/linux-pam/linux-pam/blob/e3b66a60e4209e019cf6a45f521858cec2dbefa1/modules/pam_unix/support.c#L212
    # Cost can be found in header: j7T=3, j8T=4, j9T=5 (default), jAT=6, jBT=7, jCT=8, jDT=9, jET=10, jFT=11
    # https://linux-audit.com/authentication/linux-password-security-hashing-rounds/#configuration-pam
    # This is so undocumented but you can change the yescrypt cost in mkpasswd by supplying a salt
    # https://relentlesscoding.com/posts/upgrade-linux-password-hashing-method/#:~:text=(Incidentally%2C%20password%20verification%20is%20made,is%20you%20still%20find%20bearable.
    # mkpasswd -m yescrypt -S '$y$<cost>$<salt>'
    # First get a random salt by running `mkpasswd`. Run again with chosen cost and salt:
    # mkpasswd -m yescrypt -S '$y$jBT$Fd7r0SHHauIRYKfbnBSV40'
    users = {
      groups = {
        multimedia = { };
      };
      mutableUsers = false;
      users =
        let
          adminAccess = {
            hashedPassword = lib.mkDefault config.admin.hashedPassword;
            openssh.authorizedKeys.keys = sshPublicKeys.allAdminKeys;
            shell = pkgs.zsh;
          };
        in
        {
          root = adminAccess;
          ${config.admin.username} = adminAccess // {
            isNormalUser = true;
            # https://wiki.archlinux.org/title/Users_and_groups#Group_list
            extraGroups = [
              "networkmanager"
              "wheel"
              "tty"
              "dialout"
              "audio"
              "video"
              "cdrom"
              "multimedia"
              "libvirtd"
            ];
          };
        };
    };

    programs = {
      zsh.enable = true;
      starship = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ../../misc/starship.toml);
      };
      git.enable = true;
      nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 7d --keep 7";
        };
        flake = "/home/${config.admin.username}/.config/nixflake";
      };
    };

    environment = {
      systemPackages = [
        pkgs.vim
        pkgs.neovim
        pkgs.bat
        pkgs.fd
        pkgs.ripgrep
        pkgs.tealdeer
        pkgs.unzip
        pkgs.git
        pkgs.eza
        pkgs.curl
        pkgs.dig.dnsutils
        pkgs.usbutils # lsusb -v
        pkgs.pciutils # lspci -a
        pkgs.unixtools.ifconfig
      ];
      pathsToLink = [ "/share/zsh" ];
    };

    services = {

      # Nice to have, required for gnome-disks to work
      udisks2.enable = true;

      openssh = {
        enable = true;
        settings = {
          ClientAliveCountMax = 3; # See below
          ClientAliveInterval = 600; # 10 min x 3 = 30 min idle timeout
          DisableForwarding = true; # No X11, ssh_agent, or tcp forwarding by default
          KbdInteractiveAuthentication = false; # No interactive logins
          PasswordAuthentication = false; # Extremely important!!!
          PermitRootLogin = "prohibit-password"; # The default but still worth specifying
        };
      };

    };

    virtualisation.vmVariant = {
      virtualisation = {
        memorySize = 4096;
        cores = 4;
      };
    };

    # nixos-rebuild list-generations
    system.nixos.label =
      let
        selfRev = if (inputs.self ? rev) then inputs.self.shortRev else inputs.self.dirtyShortRev;
      in
      # 25.11-1fd8bad-d99a35e-dirty
      "${config.system.nixos.release}-${inputs.nixpkgs.shortRev}-${selfRev}";

  };
}

{
  # nix-repl> :lf .
  # nix-repl> pkgs = import inputs.nixpkgs { system = builtins.currentSystem; }

  description = "My Personal NixOS System Flake Configuration";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # nixpkgs.url = "/home/stel/code/nixpkgs/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager.url = "/home/stel/code/home-manager";
    home-manager = {
      # url = "github:nix-community/home-manager/release-24.11";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-alien = {
    #   url = "github:thiagokokada/nix-alien";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.nix-index-database.follows = "nix-index-database";
    # };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # For accessing `deploy-rs`'s utility Nix functions
    deploy-rs.url = "github:serokell/deploy-rs";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arcsearch = {
      url = "github:massivebird/arcsearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wayland-pipewire-idle-inhibit = {
      url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin-btop = {
      url = "github:catppuccin/btop";
      flake = false;
    };
    rsync-ng-yazi = {
      url = "github:stelcodes/rsync-ng.yazi";
      flake = false;
    };
    audio = {
      url = "github:polygon/audio.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {

    nixosModules = {
      generators-custom-formats =
        { config, ... }:
        {
          imports = [ inputs.nixos-generators.nixosModules.all-formats ];
          formatConfigs = {
            install-iso-plasma =
              { modulesPath, ... }:
              {
                formatAttr = "isoImage";
                fileExtension = ".iso";
                imports = [
                  "${toString modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix"
                ];
              };
            install-iso-gnome =
              { modulesPath, ... }:
              {
                formatAttr = "isoImage";
                fileExtension = ".iso";
                imports = [
                  "${toString modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
                ];
              };
          };
        };
    };

    homeConfigurations = {
      marlene = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs { system = "aarch64-darwin"; };
        modules = [
          ./hosts/marlene/home.nix
          ./modules/common/home.nix
          # Only need to import this as a hm module in standalone hm configs
          ./modules/common/nixpkgs.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
        };
      };
    };

    nixosConfigurations =
      let
        nixosMachine =
          { system, hostName }:
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs; };
            modules = [
              { networking.hostName = hostName; }
              ./modules/common
              ./hosts/${hostName}
            ];
          };
      in
      {
        # 12th gen intel framework laptop
        yuffie = nixosMachine {
          hostName = "yuffie";
          system = "x86_64-linux";
        };
        # desktop tower
        # terra = nixosMachine {
        #   hostName = "terra";
        #   system = "x86_64-linux";
        # };
        # 2013 macbook air
        # aerith = nixosMachine {
        #   hostName = "aerith";
        #   system = "x86_64-linux";
        # };
        # mac mini 2011 beatrix
        # beatrix = nixosMachine {
        #   hostName = "beatrix";
        #   system = "x86_64-linux";
        # };
        # raspberry pi 3B+
        # nix build .#nixosConfigurations.boko.config.formats.sd-aarch64 (build is failing atm)
        # https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux
        # https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi.html
        # boko = nixosMachine {
        #   hostName = "boko";
        #   system = "aarch64-linux";
        # };
        hetznercloud = nixosMachine {
          hostName = "hetznercloud";
          system = "x86_64-linux";
        };
        sora = nixosMachine {
          hostName = "sora";
          system = "x86_64-linux";
        };
        # basic virtual machine for experimenting
        # sandbox = nixosMachine {
        #   hostName = "sandbox";
        #   system = "x86_64-linux";
        # };
        installer = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.self.nixosModules.generators-custom-formats
            (
              { pkgs, config, ... }:
              {
                nixpkgs.config.allowUnfree = true;
                environment.systemPackages = [
                  pkgs.git
                  pkgs.neovim
                ];
                boot = {
                  kernelModules = [ "wl" ];
                  extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
                };
              }
            )
          ];
        };
      };

    # https://github.com/serokell/deploy-rs?tab=readme-ov-file#overall-usage
    deploy.nodes =
      let
        system = "x86_64-linux";
        pkgs = import inputs.nixpkgs { inherit system; };
        deployPkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.deploy-rs.overlays.default
            (self: super: {
              deploy-rs = {
                inherit (pkgs) deploy-rs;
                lib = super.deploy-rs.lib;
              };
            })
          ];
        };
      in
      {
        sora = {
          hostname = "178.156.164.233";
          # hostname = "sora";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos inputs.self.nixosConfigurations.sora;
            remoteBuild = false; # build on the target system
          };
        };
      };

    # This is highly advised by deploy-rs
    checks = builtins.mapAttrs (
      system: deployLib: deployLib.deployChecks inputs.self.deploy
    ) inputs.deploy-rs.lib;

  };
}

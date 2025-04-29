{ lib, inputs, pkgs, ... }: {
  config = {
    nix = {
      package = pkgs.nixVersions.latest;
      gc = {
        automatic = false; # replacing with nh systemd clean service
        options = "--delete-older-than 30d";
      };
      settings = {
        # Toggling auto-optimise-store actually corrupted my Nix store!
        # Fix: sudo nix-store --verify --check-contents --repair
        auto-optimise-store = false; # Dangerous!
        experimental-features = [ "nix-command" "flakes" ];
        flake-registry = ""; # Disable global flake registry
        keep-outputs = true; # Keep build artifacts around to avoid rebuilding
      };
      extraOptions = ''
        warn-dirty = false
      '';
      registry.nixpkgs.flake = inputs.nixpkgs; # For flake commands
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # For legacy commands
    };
    nixpkgs =
      let
        config = {
          permittedInsecurePackages = [ ];
          allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
            "obsidian"
            "spotify"
            "bitwig-studio"
            "graillon"
            "steam"
            "steam-original"
            "steam-run"
            "vital"
            "broadcom-sta"
            "facetimehd-firmware"
            "facetimehd-calibration"
            "libretro-snes9x"
            "vscode"
            "zsh-abbr"
          ];
        };
      in
      {
        inherit config;
        overlays = [
          # (final: prev: {
          #   unstable = import inputs.nixpkgs-unstable { inherit config; system = final.system; };
          # })
          (import ../../packages/overlay.nix)
        ];
      };
  };
}

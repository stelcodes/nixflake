{ pkgs, inputs, ... }: {

  home = {
    stateVersion = "23.05";
    packages = [
      pkgs.obsidian-jailed
      pkgs.gimp-with-plugins
      pkgs.gajim
      pkgs.signal-desktop
      pkgs.fractal
      # inputs.gpt4all-nix.packages.${pkgs.system}.default
      pkgs.unstable.gpt4all
      # inputs.arcsearch.packages.${pkgs.system}.default
      pkgs.retroarch-loaded
      pkgs.kodi-loaded
      pkgs.flac
      pkgs.pdfcpu # Convert a pdf to booklet for printing!
      pkgs.smartmontools # Tools for monitoring the health of hard drives
      pkgs.cheese # for testing webcams
      pkgs.amdgpu_top
      # pkgs.lact # amdgpu controller daemon + gui https://github.com/ilya-zlobintsev/LACT
      pkgs.blender-hip # Includes HIP libraries needed for AMD GPU
      pkgs.libreoffice
      pkgs.guitarix
      pkgs.gxplugins-lv2
      pkgs.bk
      pkgs.dconf2nix
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-pipewire-audio-capture
          obs-vaapi # https://wiki.archlinux.org/title/Open_Broadcaster_Software#Encoding_using_GStreamer
        ];
      })
      pkgs.easyeffects
      pkgs.calibre
      pkgs.kdenlive
      pkgs.ffmpeg
      pkgs.discord-firefox
      pkgs.spotify-firefox
      pkgs.dconf-editor
      pkgs.picard # Music tagging (mp3, flac, everything)
      pkgs.chromium
      pkgs.git-fiddle
      (pkgs.firejailWrapper {
        executable = "${pkgs.vscode}/bin/code";
        extraArgs = [ "--noprofile" "--whitelist=\"$HOME/code\"" "--whitelist=\"$HOME/.config\"" "--whitelist=\"$HOME/.local\"" ];
      })
      pkgs.yazi
      pkgs.nix-tree
      # Build time dependencies of a flake on the current directory
      # nix-tree --derivation '.#'
      # Same thing works for any flake reference
      # nix-tree --derivation 'nixpkgs#asciiquarium'
    ];
  };
  wayland.windowManager.sway = {
    config.workspaceOutputAssign = [
      { output = "HDMI-A-1"; workspace = "5"; }
    ];
    mainDisplay = "DP-1";
    sleep = {
      lockBefore = false;
      auto = {
        enable = true;
        idleMinutes = 15;
      };
    };
    wallpaper = pkgs.wallpaper.rei-moon;
  };
}

# ~/.vital/Vital.config
# {"synth_version":"1.5.5","work_offline":true,"data_directory":"/run/media/archive/music/presets/vital"}

{ lib, config, ... }: {

  # https://github.com/robbert-vdh/yabridge?tab=readme-ov-file#performance-tuning

  config = lib.mkIf config.profile.audio {

    # Needed for pipewire
    security.rtkit.enable = true;

    services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };

    environment.variables =
      let
        makePluginPath = format:
          # Yabridge uses the first entry for installation directory so it needs to be writable
          "$HOME/.${format}:" +
          (lib.makeSearchPath format [
            "$HOME/.nix-profile/lib"
            "/run/current-system/sw/lib"
            "/etc/profiles/per-user/$USER/lib"
          ]);
      in
      lib.mkForce {
        DSSI_PATH = makePluginPath "dssi";
        LADSPA_PATH = makePluginPath "ladspa";
        LV2_PATH = makePluginPath "lv2";
        LXVST_PATH = makePluginPath "lxvst";
        VST_PATH = makePluginPath "vst";
        VST3_PATH = makePluginPath "vst3";
        CLAP_PATH = makePluginPath "clap";
      };

  };

}

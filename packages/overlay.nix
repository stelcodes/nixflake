# Using prev can cause unpredictable cache misses:
# https://discourse.nixos.org/t/packages-in-overlay-arguments-are-different-from-regular-package-set/50729
final: prev: {
  success-alert = final.fetchurl {
    # https://freesound.org/people/martcraft/sounds/651624/
    url = "https://cdn.freesound.org/previews/651/651624_14258856-lq.mp3";
    sha256 = "urNwmGEG2YJsKOtqh69n9VHdj9wSV0UPYEQ3caEAF2c=";
  };
  failure-alert = final.fetchurl {
    # https://freesound.org/people/martcraft/sounds/651625/
    url = "https://cdn.freesound.org/previews/651/651625_14258856-lq.mp3";
    sha256 = "XAEJAts+KUNVRCFLXlGYPIJ06q4EjdT39G0AsXGbT2M=";
  };
  pomo-alert = final.fetchurl {
    # https://freesound.org/people/dersinnsspace/sounds/421829/
    url = "https://cdn.freesound.org/previews/421/421829_8224400-lq.mp3";
    sha256 = "049x6z6d3ssfx6rh8y11var1chj3x67nfrakigydnj3961hnr6ar";
  };
  wallpaper = {
    rei-moon = final.fetchurl {
      url = "https://i.imgur.com/NnXQqDZ.jpg";
      hash = "sha256-yth6v4M5UhXkxQ/bfd3iwFRi0FDGIjcqR37737D8P5w=";
    };
    halcyondaze = final.fetchurl {
      url = "https://i.imgur.com/obIghpJ.png";
      hash = "sha256-ar+Zbf/DN7bc9tAnQFi6qR8TPoBREzCb3d65HoOez5s=";
    };
    anime-girl-cat = final.fetchurl {
      url = "https://i.imgur.com/sCV0yu7.jpg";
      hash = "sha256-qDt+Gj21M2LkMo80sXICCzy/LjOkAqeN4la/YhaLBmM=";
    };
    anime-girl-coffee = final.fetchurl {
      url = "https://i.imgur.com/lR2iapT.jpg";
      hash = "sha256-JtY6vWns88mZ29fuYBYZO1NoD+O1YxPb9EBfotv7yb0=";
    };
  };
  pomo = final.callPackage ./pomo.nix { };
  writeBabashkaScript = final.callPackage ./write-babashka-script.nix { };
  tmux-snapshot = final.callPackage ./tmux-snapshot { };
  tmux-startup = final.callPackage ./tmux-startup { };
  devflake = final.callPackage ./devflake { };
  truecolor-test = final.writeShellApplication {
    name = "truecolor-test";
    runtimeInputs = [ final.coreutils final.gawk ];
    text = ''
      awk 'BEGIN{
          s="/\\/\\/\\/\\/\\"; s=s s s s s s s s s s s s s s s s s s s s s s s;
          for (colnum = 0; colnum<256; colnum++) {
              r = 255-(colnum*255/255);
              g = (colnum*510/255);
              b = (colnum*255/255);
              if (g>255) g = 510-g;
              printf "\033[48;2;%d;%d;%dm", r,g,b;
              printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
              printf "%s\033[0m", substr(s,colnum+1,1);
          }
          printf "\n";
      }'
    '';
  };
  toggle-service = final.writeShellApplication {
    name = "toggle-service";
    runtimeInputs = [ final.systemd ];
    text = ''
      SERVICE="$1.service"
      if ! systemctl --user cat "$SERVICE" &> /dev/null; then
        echo "ERROR: Service does not exist"
        exit 1
      fi
      if systemctl --user is-active "$SERVICE"; then
        echo "Stopping service"
        systemctl --user stop "$SERVICE"
      else
        echo "Starting service"
        systemctl --user start "$SERVICE"
      fi
    '';
  };
  check-newline = final.writeShellApplication {
    name = "check-newline";
    runtimeInputs = [ final.coreutils ];
    text = ''
      filename="$1"
      if [ ! -s "$filename" ]; then
        echo "$filename is empty"
      elif [ -z "$(tail -c 1 <"$filename")" ]; then
        echo "$filename ends with a newline or with a null byte"
      else
        echo "$filename does not end with a newline nor with a null byte"
      fi
    '';
  };
  wg-killswitch = final.callPackage ./wg-killswitch { };
  createBrowserApp = { name, url, package ? final.ungoogled-chromium, icon ? "browser" }:
    let
      pname = final.lib.replaceStrings [ " " ] [ "-" ] (final.lib.toLower name);
      exec = final.writeShellApplication {
        name = pname;
        text = ''
          ${final.lib.getExe package} --new-window --app='${url}'
        '';
      };
    in
    final.makeDesktopItem {
      name = pname;
      exec = final.lib.getExe exec;
      icon = icon;
      desktopName = name;
      genericName = pname;
      comment = "Open ${url} in ${package.meta.name}";
      categories = [ "Network" ];
    };
  kodi-loaded = final.kodi.withPackages (p: [
    p.visualization-goom
    p.somafm
    p.radioparadise
    p.joystick
    p.youtube
  ]);
  retroarch-loaded = final.retroarch.override {
    settings = {
      menu_driver = "xmb";
      xmb_menu_color_theme = "15"; # cube purple
      assets_directory = "${final.retroarch-assets}/share/retroarch/assets";
      savefile_directory = "~/sync/games/saves";
      savestate_directory = "~/sync/games/states";
      screenshot_directory = "~/sync/games/screenshots";
      playlist_directory = "~/sync/games/playlists";
      thumbnails_directory = "~/sync/games/thumbnails";
      content_favorites_path = "~/sync/games/content_favorites.lpl";
      playlist_entry_remove_enable = "0";
      playlist_entry_rename = "false";
      input_menu_toggle_gamepad_combo = "7"; # hold start for quick menu
      menu_swap_ok_cancel_buttons = "true";
      auto_overrides_enable = "true"; # Auto setup controllers
      auto_remaps_enable = "true"; # Auto load past remaps
    };
    cores = with final.libretro; [
      # pkgs/applications/emulators/retroarch/cores.nix
      mesen # nes
      snes9x # snes
      mupen64plus # n64
      dolphin # gamecube/wii
      swanstation # ps1
      sameboy # gb
      mgba # gba
      ppsspp # psp
    ];
  };
  syncthing-tray = final.syncthing-tray.overrideAttrs {
    meta.mainProgram = "syncthing-tray";
  };
  audacious = final.audacious.overrideAttrs {
    meta.mainProgram = "audacious";
  };
  firejailWrapper = { executable, desktop ? null, profile ? null, extraArgs ? [ ] }: final.runCommand "firejail-wrap"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
      meta.priority = -1; # take precedence over non-firejailed versions
    }
    (
      let
        firejailArgs = final.lib.concatStringsSep " " (
          extraArgs ++ (final.lib.optional (profile != null) "--profile=${toString profile}")
        );
      in
      ''
        command_path="$out/bin/$(basename ${executable})-jailed"
        mkdir -p $out/bin
        mkdir -p $out/share/applications
        cat <<'_EOF' >"$command_path"
        #! ${final.runtimeShell} -e
        exec /run/wrappers/bin/firejail ${firejailArgs} -- ${toString executable} "\$@"
        _EOF
        chmod 0755 "$command_path"
      '' + final.lib.optionalString (desktop != null) ''
        substitute ${desktop} $out/share/applications/$(basename ${desktop}) \
          --replace ${executable} "$command_path"
      ''
    );
  obsidian-jailed = final.firejailWrapper {
    executable = "${final.obsidian}/bin/obsidian";
    desktop = "${final.obsidian}/share/applications/obsidian.desktop";
    extraArgs = [ "--noprofile" "--whitelist=\"$HOME/notes\"" "--whitelist=\"$HOME/.config/obsidian\"" ];
  };
  desktop-entries = final.writeShellApplication {
    name = "desktop-entries";
    runtimeInputs = [ final.coreutils-full final.findutils ];
    text = ''
      data_dirs="$XDG_DATA_DIRS:$HOME/.local/share"
      matches=""
      for p in ''${data_dirs//:/ }; do
        printf -v matches "%s%s" "$matches" "$(find "$p/applications" -name '*.desktop' 2>/dev/null || true)"
      done
      printf "%s" "$matches" | sort | uniq
    '';
  };
  git-fiddle = final.callPackage ./git-fiddle.nix { };
  convert-audio = final.callPackage ./convert-audio { };
  rekordbox-add = final.callPackage ./rekordbox-add { };
  mpv-unify = final.callPackage ./mpv-unify { };
  pam-parallel = final.callPackage ./pam-parallel { };
  writePythonApplication =
    # My own custom python writer that uses ruff instead of flake8. Name collision purposefully avoided.
    { name
    , runtimeInputs ? [ ]
    , libraries ? [ ]
    , checkIgnore ? [ ]
    , doCheck ? true
    , text
    }:
    let
      python = final.python3;
      ignoreAttribute =
        final.lib.optionalString (checkIgnore != [ ])
          "--ignore ${final.lib.concatMapStringsSep "," final.lib.escapeShellArg checkIgnore}";
    in
    final.writers.makeScriptWriter
      {
        interpreter = (python.withPackages (ps: libraries)).interpreter;
        makeWrapperArgs =
          if runtimeInputs != [ ] then
            [ "--prefix PATH : ${final.lib.makeBinPath runtimeInputs}" ]
          else [ ];
        check = final.lib.optionalString doCheck (
          final.writers.writeDash "pythoncheck.sh" ''
            exec ${final.ruff}/bin/ruff check ${ignoreAttribute} "$1"
          ''
        );
      }
      "/bin/${name}"
      text;
  wg-quick-wofi = final.writeShellApplication {
    name = "wg-quick-wofi";
    runtimeInputs = [ final.coreutils-full final.systemd final.gnugrep final.gnused final.wofi final.libnotify ];
    text = ''
      # Services that aren't enabled are never listed with list-unit command unless active
      services="$(systemctl list-unit-files --type service --no-legend 'wg-quick-*' | grep wg-quick- | cut -d ' ' -f1)"
      x="$(systemctl list-units --type service --no-legend --state active 'wg-quick-*' | grep wg-quick- | cut -d ' ' -f3 | tail -1)"
      if [ -n "$x" ]; then
        services="$(printf "%s" "$services" | sed "/^$x/d")"
        sel="$(printf "Stop %s\n%s" "$x" "$services" | wofi --dmenu --lines 4)"
      else
        sel="$(printf "%s" "$services" | wofi --dmenu --lines 4)"
      fi
      if [ "$sel" = "Stop $x" ]; then
        if systemctl stop "$x"; then
          notify-send "Stopped $x"
        else
          notify-send --urgency=critical "Failed to stop $x"
        fi
      else
        if systemctl start "$sel"; then
          notify-send "Started $sel"
          if systemctl stop "$x"; then
            notify-send "Stopped $x"
          else
            notify-send --urgency=critical "Failed to stop $x"
          fi
        else
          notify-send --urgency=critical "Failed to start $sel"
        fi
      fi
    '';
  };
  everforest-gtk-theme = final.callPackage ./everforest-gtk-theme.nix { };
  open-browser-app = final.writeShellApplication {
    # I would use luakit if there was an easy way to open new windows
    # https://github.com/luakit/luakit/issues/509
    name = "open-browser-app";
    text = ''
      ${final.lib.getExe final.ungoogled-chromium} --new-window --app="$1"
    '';
  };
}

{ pkgs, lib, inputs, config, ... }: {

  imports = [
    ./options.nix
    ../neovim/home.nix
    ../tmux/home.nix
    ../graphical/home.nix
    ../sway/home.nix
    ../audio/home.nix
    inputs.nix-index-database.hmModules.nix-index
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
    inputs.agenix.homeManagerModules.default
  ];

  config = {

    news.display = "silent";

    systemd.user = lib.mkIf pkgs.stdenv.isLinux {
      settings.Manager = {
        DefaultTimeoutStopSec = 10;
        DefaultTimeoutAbortSec = 10;
      };
      startServices = true;
      services = {
        env-check = {
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/env";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
    };

    xdg.userDirs = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/desktop";
      documents = "$HOME/documents";
      download = "$HOME/downloads";
      music = "$HOME/music";
      pictures = "$HOME/pictures";
      publicShare = "$HOME/public";
      templates = "$HOME/template";
      videos = "$HOME/videos";
    };

    home = {
      username = lib.mkDefault "${config.admin.username}";
      homeDirectory = lib.mkDefault "/home/${config.admin.username}";

      packages = [
        pkgs.trash-cli
        pkgs.fd
        pkgs.microfetch
        pkgs.wget
        pkgs.ripgrep
        pkgs.unzip
        pkgs.truecolor-test
        pkgs.dua
        pkgs.jq
        pkgs.tmux-startup
        # pkgs.unrar
      ] ++ (lib.lists.optionals pkgs.stdenv.isLinux [
        pkgs.desktop-entries
        pkgs.toggle-service
        # inputs.nix-alien.packages.${pkgs.system}.nix-alien
      ]) ++ (lib.lists.optionals config.activities.coding [
        pkgs.nix-prefetch-github
        pkgs.nixpkgs-fmt
        pkgs.check-newline
        pkgs.doctl
        pkgs.yt-dlp
        pkgs.croc
        pkgs.restic
        pkgs.gh
        pkgs.git-backdate
        pkgs.devflake
        pkgs.p7zip
        pkgs.mediainfo # for yazi
        inputs.agenix.packages.${pkgs.system}.default
        pkgs.git-cliff
        pkgs.nix-inspect
      ]);

      sessionVariables = {
        EDITOR = "nvim";
        PAGER = "less --chop-long-lines --RAW-CONTROL-CHARS";
        MANPAGER = "nvim +Man!";
        BAT_THEME = "ansi";
        NH_FLAKE = "/home/${config.admin.username}/.config/nixflake";
      };

      file = {
        ".hm-generation-source".source = ../..;
        ".ExifTool_config".source = ../../misc/exiftool-config.pl;
      };
    };

    programs = {
      # Let Home Manager install and manage itself.
      home-manager.enable = true;

      # Use "," command to run programs not currently installed with prebuilt nixpkgs index
      nix-index.enable = true;
      nix-index-database.comma.enable = true;

      ssh = {
        # Let's avoid broken pipes over unreliable connections
        # https://unix.stackexchange.com/a/3027
        # The client will wait idle for 60 seconds then send a "no-op null
        # packet" to the server and expect a response. If no response comes,
        # then it will keep trying the above process 10 iterations (600
        # seconds). If the server still doesn't respond, then the client
        # disconnects the ssh connection.
        serverAliveInterval = 60;
        serverAliveCountMax = 10;
      };

      bat = {
        enable = true;
        config = {
          theme = "ansi";
          paging = "always";
          style = "header,grid,snip";
        };
      };

      btop = {
        enable = true;
        settings = {
          color_theme = config.theme.set.btop;
          vim_keys = true;
        };
      };

      git = {
        enable = true;
        userName = "Stel Clementine";
        userEmail = "dev@stelclementine.com";
        ignores = [
          "*Session.vim"
          "*.DS_Store"
          "*.swp"
          "*.direnv"
          "/direnv"
          "/local"
          "/node_modules"
          "*.jar"
          "*~"
          "*.swp"
          "*.#"
          "/.lsp"
          "/.clj-kondo"
          "/result"
          "/target"
          "/dist"
          "/out"
        ];
        extraConfig = {
          core.editor = "nvim";
          init = { defaultBranch = "main"; };
          merge = { ff = "only"; };
          push.autoSetupRemote = true;
          # url = {
          #   "git@github.com:".insteadOf = "https://github.com/";
          # };
          # pull.rebase = "true";
        };
        delta = {
          enable = true;
          options = {
            decorations = {
              commit-style = "bold yellow ul";
              commit-decoration-style = "";
              file-style = "yellow";
              file-decoration-style = "";
              hunk-header-style = "omit";
              minus-style = "normal #49343a";
              plus-style = "normal #2f4030";
              zero-style = "";
            };
            features = "decorations";
          };
        };
      };

      fzf.enable = true;

      direnv = {
        enable = config.activities.coding;
        nix-direnv.enable = true;
      };

      tealdeer = {
        enable = true;
        settings.updates.auto_update = true; # Uses cache for 30 days
      };

      zoxide.enable = true;

      yazi = {
        enable = true;
        # Remove all media preview deps when machine is headless
        package = lib.mkIf config.profile.graphical (pkgs.yazi.override { optionalDeps = [ ]; });
        shellWrapperName = "y";
        # Defaults: https://github.com/sxyazi/yazi/tree/main/yazi-config/preset
        settings = {
          mgr = {
            show_hidden = false;
            sort_by = "natural";
            sort_translit = true;
          };
          plugin.prepend_fetchers = [
            # https://github.com/yazi-rs/plugins/tree/main/git.yazi#setup
            { id = "git"; name = "*"; run = "git"; }
            { id = "git"; name = "*/"; run = "git"; }
          ];
          plugin.prepend_preloaders = [
            { mime = "video/*"; run = "noop"; }
          ];
          opener = {
            play = lib.mkIf config.profile.graphical [
              # mpv-unify script from mpv package prevents simultaneous playback
              # { desc = "Play"; run = "${pkgs.mpv-unify.override { mpv = config.programs.mpv.finalPackage; }}/bin/mpv-unify \"$@\""; orphan = true; for = "unix"; }
            ];
            dj = lib.mkIf (config.profile.graphical && config.activities.djing) [
              # { desc = "Queue"; run = "${pkgs.mpv-unify.override { mpv = config.programs.mpv.finalPackage; }}/bin/mpv-unify --queue \"$@\""; orphan = true; for = "unix"; }
              { desc = "Rekordbox"; run = "${pkgs.rekordbox-add}/bin/rekordbox-add \"$@\""; block = true; for = "unix"; }
              { desc = "Convert audio"; run = "${pkgs.convert-audio}/bin/convert-audio \"$1\""; block = true; for = "unix"; }
            ];
          };
          # file -bL --mime-type <file>
          # Can check mimetype with yazi spot window (tab)
          open.prepend_rules = [
            { mime = "inode/directory"; use = [ "open" "reveal" ]; }
            { mime = "video/*"; use = [ "open" "reveal" ]; }
            { mime = "audio/*"; use = [ "open" "reveal" ] ++ (lib.optionals config.activities.djing [ "dj" ]); }
          ];
        };
        plugins =
          let
            yp = pkgs.yaziPlugins;
            _mkYaziPlugin = (initLua:
              "${(pkgs.writeTextDir "plugin/main.lua" initLua)}/plugin"
            );
          in
          {
            chmod = yp.chmod;
            full-border = yp.full-border;
            toggle-pane = yp.toggle-pane;
            mount = yp.mount;
            git = yp.git;
            starship = yp.starship;
            smart-enter = yp.smart-enter;
            rsync-ng = inputs.rsync-ng-yazi;
          };
        initLua = /* lua */ ''
          -- Old tab bar style https://github.com/sxyazi/yazi/pull/2782
          function Tabs.height() return 0 end
          Header:children_add(function()
            if #cx.tabs == 1 then return "" end
            local spans = {}
            for i = 1, #cx.tabs do
              spans[#spans + 1] = ui.Span(" " .. i .. " ")
            end
            spans[cx.tabs.idx]:reverse()
            return ui.Line(spans)
          end, 9000, Header.RIGHT)
          require("starship"):setup()
          require("git"):setup()
        '';
        keymap = {
          mgr.prepend_keymap = [
            {
              on = "M";
              run = "plugin mount";
              desc = "Manage disks and volumes";
            }
            {
              on = "=";
              run = "plugin toggle-pane max-current";
              desc = "Maximize or restore the preview pane";
            }
            {
              on = "+";
              run = "plugin toggle-pane max-preview";
              desc = "Maximize or restore the preview pane";
            }
            {
              on = [ "c" "m" ];
              run = "plugin chmod";
              desc = "Chmod on selected files";
            }
            {
              on = "!";
              run = "shell \"$SHELL\" --block";
              desc = "Open shell here";
            }
            {
              on = "q";
              run = "close";
              desc = "Close the current tab, or quit if it is last tab";
            }
            {
              on = "<Enter>";
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
            {
              on = "R";
              run = "plugin rsync-ng";
              desc = "Copy files using rsync";
            }
            # Bookmarks (g, h, c, d, <space> are preserved from default keymap)
            { on = [ "g" "n" ]; run = "cd /nix/store"; desc = "Goto /nix/store"; }
            { on = [ "g" "C" ]; run = "cd ~/.config/nixflake"; desc = "Goto nixflake"; }
            { on = [ "g" "l" ]; run = "cd ~/.local"; desc = "Goto ~/.local"; }
            { on = [ "g" "t" ]; run = "cd ~/tmp"; desc = "Goto ~/tmp"; }
            { on = [ "g" "T" ]; run = "cd /tmp"; desc = "Goto /tmp"; }
            { on = [ "g" "m" ]; run = "cd ~/music"; desc = "Goto ~/Music"; }
            { on = [ "g" "M" ]; run = "cd /run/media"; desc = "Goto /run/media"; }
            { on = [ "g" "r" ]; run = "cd ~/music/dj-tools/rekordbox"; desc = "Goto rekordbox"; }
          ] ++ lib.optionals pkgs.stdenv.isDarwin [
            { on = [ "g" "v" ]; run = "cd /Volumes"; desc = "Goto /Volumes"; }
            { on = [ "g" "i" ]; run = "cd '~/Library/Mobile Documents/com~apple~CloudDocs'"; desc = "Goto iCloud"; }
          ];
        };
      };

      starship = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ../../misc/starship.toml);
      };

      bash.enable = true;

      zsh =
        let
          gitName = config.programs.git.userName;
          gitEmail = config.programs.git.userEmail;
          aliases = rec {
            t = "tmux-startup";
            ll = "ls -l";
            la = "ls -A";
            rm = "rm -i";
            mv = "mv -n";
            r = "rsync -ah"; # use --delete-delay when necessary
            gs = "git status";
            gl = "git log";
            glf = "git log --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%an%C(reset) %C(cyan)%cr%C(reset) %s %C(green)%d%C(reset)' --graph";
            d = "dua --stay-on-filesystem interactive";
            ssh-key-create = "ssh-keygen -a 100 -t ed25519 -f ./id_ed25519 -C \"$(whoami)@$(hostname)@$(date +'%Y-%m-%d')\"";
            date-sortable = "date +%Y-%m-%dT%H:%M:%S%Z"; # ISO 8601 date format with local timezone
            date-sortable-utc = "date -u +%Y-%m-%dT%H:%M:%S%Z"; # ISO 8601 date format with UTC timezone
            dl-base = "yt-dlp --embed-metadata --embed-thumbnail --progress --download-archive ./yt-dlp-archive.txt --user-agent 'Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0'";
            dl-video = "${dl-base} --embed-subs --sub-langs 'en' --embed-chapters --sponsorblock-mark 'default' --sponsorblock-remove 'sponsor' --remux-video 'mkv'";
            dl-video-yt = "${dl-video} --no-playlist --output '%(uploader_id,uploader)s/%(upload_date)s - %(uploader_id,uploader)s - %(title)s [%(id)s].%(ext)s'";
            yt = dl-video-yt;
            dl-video-yt-playlist = "${dl-video} --output '%(uploader_id,uploader)s - %(playlist)s/%(playlist_index).3d - %(upload_date)s - %(uploader_id,uploader)s - %(title)s [%(id)s].%(ext)s'";
            dl-video-1080 = "${dl-video} --format 'bestvideo[height<=1080]+bestaudio'";
            dl-video-1080-yt-playlist = "${dl-video-yt-playlist} --format 'bestvideo[height<=1080]+bestaudio'";
            # console.log(Array.from(document.querySelectorAll('li.music-grid-item a')).map(el => el.href).join("\n")) -> copy paste to file -> -a <filename>
            dl-audio-bc = "${dl-base} --format 'flac' --output '%(album,track,title|Unknown Album)s - %(track_number|00).2d - %(artist,uploader|Unknown Artist)s - %(track,title,webpage_url)s.%(ext)s'";
            dl-audio-yt = "${dl-base} --format 'bestaudio[acodec=opus]' --extract-audio";
            dl-yarn = "${dl-base} --extract-audio --output \"$HOME/music/samples/yarn/$(read).%(ext)s\"";
            noansi = "sed \"s,\\x1B\\[[0-9;]*[a-zA-Z],,g\"";
            loggy = " |& tee /tmp/loggy-$(${date-sortable}).log";
            network-test = "ping -c 1 -W 5 8.8.8.8";
            rs = lib.mkDefault "nh os switch"; # rebuild switch
            rebuild = lib.mkDefault "sudo nixos-rebuild switch --flake \"$HOME/.config/nixflake#\"";
            nix-repl-flake = "nix repl --expr \"(builtins.getFlake (toString $HOME/.config/nixflake)).nixosConfigurations.$hostname\"";
            nix-pkg-size = "nix path-info --closure-size --human-readable --recursive";
            nix-shell-nixpkgs = "nix shell --file .";
            nix-shell-default = "nix shell --impure --include nixpkgs=flake:nixpkgs --expr 'with import <nixpkgs> {}; { default = callPackage ./default.nix {}; }' default";
            nix-build-default = "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
            nix-dependency = "nix-store --query --referrers /nix/store/";
            nix-bigstuff = "nix path-info -rS /run/current-system | sort -nk2";
            nix-why = "nix why-depends /run/current-system /nix/store/";
            caddy-server = "echo 'http://localhost:3030' && caddy file-server --listen :3030 --root";
            gists = "gh gist view";
            git-reauthor-all-commits = ''git filter-branch -f --env-filter "GIT_AUTHOR_NAME='${gitName}'; GIT_AUTHOR_EMAIL='${gitEmail}'; GIT_COMMITTER_NAME='${gitName}'; GIT_COMMITTER_EMAIL='${gitEmail}';" HEAD'';
            ffmpeg = "ffmpeg -hide_banner";
            ffprobe = "ffprobe -hide_banner";
          } // lib.optionalAttrs pkgs.stdenv.isLinux {
            sc = "systemctl";
            scu = "systemctl --user";
            jc = "journalctl -ex --unit"; # Using --unit for better completion
            jcu = "journalctl -ex --user-unit"; # Using --user-unit for better completion
            ud = "udisksctl";
            sway = "exec systemd-cat --identifier=sway sway";
            swaytree = "swaymsg -t get_tree | nvim -R";
            swayinputs = "swaymsg -t get_inputs | nvim -R";
            swayoutputs = "swaymsg -t get_outputs | nvim -R";
            play = "audacious --enqueue-to-temp";
          };
        in
        {
          enable = true;
          enableCompletion = true;
          enableVteIntegration = true;
          autocd = true;
          autosuggestion.enable = true;
          cdpath = [ ];
          defaultKeymap = "viins";
          dotDir = ".config/zsh";
          history = {
            append = false;
            extended = true;
            ignorePatterns = [ "rm *" "pkill *" ];
            path = "${config.xdg.dataHome}/zsh/zsh_history";
            save = 10000;
            share = true;
          };
          historySubstringSearch.enable = true;
          # Interactive shells
          initContent = /* sh */ ''
            # export SHELL="${pkgs.zsh}/bin/zsh"
            # Make sure the Nix environment is sourced, this script is idempotent
            NIX_SETUP_SCRIPT="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
            if [ -e "$NIX_SETUP_SCRIPT" ]; then
              source "$NIX_SETUP_SCRIPT"
            fi
            # If terminal is kitty, use kitten to automatically install kitty terminfo on remote host when ssh'ing
            if [ "$TERM" = "xterm-kitty" ]; then
              alias ssh="kitty +kitten ssh"
            fi
            if [ "$(uname)" = "Darwin" ]; then # If on MacOS...
              # Append homebrew to PATH when necessary
              if [ -e /opt/homebrew ]; then
              export HOMEBREW_NO_AUTO_UPDATE=1
              export HOMEBREW_NO_ANALYTICS=1
                path+=(/opt/homebrew/bin /opt/homebrew/sbin)
              fi
              # Append local/bin to PATH if it exists
              if [ -e "$HOME/.local/bin" ]; then
                path+=("$HOME/.local/bin")
              fi
              # Fix comma falling back to 'nixpkgs' channel when NIX_PATH not set (MacOS)
              if [ ! -v NIX_PATH ]; then
                export NIX_PATH='nixpkgs=flake:${inputs.nixpkgs}'
              fi
            fi

            function copy() { ${if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy"}; }
            function paste() { ${if pkgs.stdenv.isDarwin then "pbpaste" else "wl-paste"}; }
            ${builtins.readFile ./zvm-clipboard.sh}

            # Use functions to have better kitty tab names
            function config() { cd ~/.config/nixflake && nvim; }
            function notebox() { cd ~/sync/notebox && nvim; }
          '';
          plugins = [
            {
              # Interactive git commands
              name = "forgit";
              src = pkgs.zsh-forgit;
              file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
            }
            {
              # Makes nix-shell automatically use zsh
              name = "zsh-nix-shell";
              src = pkgs.zsh-nix-shell;
              file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
            }
            {
              # Better vi mode, default one is buggy
              name = "zsh-vi-mode";
              src = pkgs.zsh-vi-mode;
              file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
            }
            {
              # Awesome fzf tab completion
              name = "zsh-fzf-tab";
              src = pkgs.zsh-fzf-tab;
              file = "share/fzf-tab/fzf-tab.plugin.zsh";
            }
            {
              # Fuzzy history search
              name = "zsh-fzf-history-search";
              src = pkgs.zsh-fzf-history-search;
              file = "share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
            }
          ];
          sessionVariables = {
            CLICOLOR = 1; # For GNU ls to have colored output
            ZVM_LINE_INIT_MODE = "i"; # For vi-mode, start new prompts in insert mode
          };
          shellAliases = aliases;
          syntaxHighlighting.enable = true;
          zprof.enable = false; # Enable to debug startup time
          zsh-abbr = {
            enable = true;
            abbreviations = aliases;
          };
        };

    };
  };
}

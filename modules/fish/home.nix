{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  home.packages = [ pkgs.starship ];
  xdg.configFile."fish/themes/base16.theme" = {
    onChange = "${pkgs.fish}/bin/fish -c 'echo y | fish_config theme save base16'";
    text = ''
      fish_color_autosuggestion brblack
      fish_color_cancel -r
      fish_color_command blue
      fish_color_comment brblack
      fish_color_cwd green
      fish_color_cwd_root red
      fish_color_end brblack
      fish_color_error red
      fish_color_escape yellow
      fish_color_history_current --bold
      fish_color_host normal
      fish_color_host_remote yellow
      fish_color_keyword blue
      # fish_color_match --background=brblue
      fish_color_normal normal
      fish_color_operator yellow
      fish_color_option cyan
      fish_color_param cyan
      fish_color_quote green
      fish_color_redirection magenta
      # fish_color_search_match 'bryellow'  '--background=brblack'
      fish_color_selection 'white'  '--bold'  '--background=brblack'
      # fish_color_status red
      # fish_color_user brgreen
      fish_color_valid_path --underline
      fish_pager_color_background
      fish_pager_color_completion normal
      fish_pager_color_description 'yellow'
      fish_pager_color_prefix 'normal'  '--bold'  '--underline'
      fish_pager_color_progress 'brwhite'  '--background=cyan'
      fish_pager_color_secondary_background
      fish_pager_color_secondary_completion
      fish_pager_color_secondary_description
      fish_pager_color_secondary_prefix
      fish_pager_color_selected_background --background=brblack
      fish_pager_color_selected_completion
      fish_pager_color_selected_description
      fish_pager_color_selected_prefix
    '';
  };
  programs.fish = {
    # enable = true;
    interactiveShellInit = # fish
      ''
        if test "$(uname)" = "Darwin"; # If on MacOS...
          # Make sure the Nix environment is sourced when fish isn't the login shell
          if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish;
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
          end
          # Set fish as the psuedo-default shell
          if test "$SHELL" = "/bin/zsh";
            set -x SHELL ${pkgs.fish}/bin/fish
          end
          # Add homebrew to PATH when necessary
          if test -e /opt/homebrew;
            fish_add_path --append /opt/homebrew/bin /opt/homebrew/sbin
          end
          # Add local/bin to PATH if it exists
          if test -e "$HOME/.local/bin";
            fish_add_path --append "$HOME/.local/bin"
          end
        end
        # Fix comma falling back to 'nixpkgs' channel when NIX_PATH not set (MacOS)
        if ! set --query NIX_PATH;
          set --export NIX_PATH 'nixpkgs=flake:${inputs.nixpkgs}'
        end
        # If ssh'ing from kitty, use kitten to automatically install kitty terminfo on remote host
        if test "$TERM" = "xterm-kitty";
          abbr ssh "kitty +kitten ssh"
        end
        set -g fish_greeting (printf (_ '🐟 don\'t be afraid to ask for %shelp%s 💞') (set_color green) (set_color normal))
        fish_vi_key_bindings
        # By default the vi mode insert cursor is a beam which I don't really like
        set fish_cursor_insert block
      '';
    loginShellInit = lib.mkDefault ''
      ${pkgs.fastfetch}/bin/fastfetch
    '';
    shellAbbrs = rec {
      ll = "ls -l";
      la = "ls -A";
      rm = "rm -i";
      mv = "mv -n";
      r = "rsync -rltxhv"; # use --delete-delay when necessary
      gs = "git status";
      gl = "git log";
      glo = "git log --oneline";
      gf = "git log --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%an%C(reset) %C(cyan)%cr%C(reset) %s %C(green)%d%C(reset)' --graph";
      sc = "systemctl";
      scu = "systemctl --user";
      # Using --unit for better fish completion
      jc = "journalctl -exf --unit";
      jcu = "journalctl --user -exf --unit";
      config = "cd ~/.config/nixflake; nvim";
      d = "dua --stay-on-filesystem interactive";
      new-ssh-key = "ssh-keygen -t ed25519";
      date-sortable = "date +%Y-%m-%dT%H:%M:%S%Z"; # ISO 8601 date format with local timezone
      date-sortable-utc = "date -u +%Y-%m-%dT%H:%M:%S%Z"; # ISO 8601 date format with UTC timezone
      beep = "timeout -s KILL 0.15 speaker-test --frequency 400 --test sin";
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
      loggy = {
        position = "anywhere";
        expansion = " &| tee /tmp/loggy-$(${date-sortable}).log";
      };
      network-test = "ping -c 1 -W 5 8.8.8.8";
      rebuild = lib.mkDefault "sudo nixos-rebuild switch --flake \"$HOME/.config/nixflake#\"";
      rebuild_ = "systemctl start --user nixos-rebuild.service";
      swaytree = "swaymsg -t get_tree | nvim -R";
      swayinputs = "swaymsg -t get_inputs | nvim -R";
      swayoutputs = "swaymsg -t get_outputs | nvim -R";
      nix-repl-flake = "nix repl --expr \"(builtins.getFlake (toString $HOME/.config/nixflake)).nixosConfigurations.$hostname\"";
      nix-pkg-size = "nix path-info --closure-size --human-readable --recursive";
      play = "audacious --enqueue-to-temp";
      strip-exec-permissions = "if test \"$(read -P 'Are you sure: ')\" = 'y'; fd -0 --type x | xargs -0 chmod -vc a-x; else; echo 'Aborting'; end";
      sway = "exec systemd-cat --identifier=sway sway";
      u = "udisksctl";
      nix-shell-nixpkgs = "nix shell --file .";
      nix-shell-default = "nix shell --impure --include nixpkgs=flake:nixpkgs --expr 'with import <nixpkgs> {}; { default = callPackage ./default.nix {}; }' default";
      nix-dependency = "nix-store --query --referrers /nix/store/";
      nix-bigstuff = "nix path-info -rS /run/current-system | sort -nk2";
      nix-why = "nix why-depends /run/current-system /nix/store/";
      caddy-server = "echo 'http://localhost:3030' && caddy file-server --listen :3030 --root";
      gists = "gh gist view";
      t = "tmux-startup";
    };
    functions = {
      wallpaper = # fish
        ''
          cp -i "$argv[1]" "$HOME/.wallpaper"
        '';
    };
  };
}

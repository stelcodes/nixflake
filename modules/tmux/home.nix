{ pkgs, config, ... }:
let
  theme = config.theme.set;
  status-left-normal = "#{?pane_in_mode,#[fg=${theme.bg}#,bg=${theme.tmuxStatusMode}#,bold],#[fg=${theme.bg}#,bg=${theme.tmuxStatusNormal}#,bold]} #S ";
  status-left-ssh = "#{?pane_in_mode,#[fg=${theme.bg}#,bg=${theme.tmuxStatusMode}#,bold],#[fg=${theme.bg}#,bg=${theme.tmuxStatusSSH}#,bold]} #S ";
  status-right-normal = "#{?client_prefix,#[fg=${theme.bg}#,bg=${theme.tmuxStatusNormal}] M-a ,}#[fg=${theme.bg4},bg=${theme.bg2}] %I:%M %p #{?pane_in_mode,#[fg=${theme.bg}#,bg=${theme.tmuxStatusMode}#,bold],#[fg=${theme.bg}#,bg=${theme.tmuxStatusNormal}#,bold]} #H ";
  status-right-ssh = "#{?client_prefix,#[fg=${theme.bg}#,bg=${theme.tmuxStatusSSH}] M-a ,}#[fg=${theme.bg4},bg=${theme.bg2}] %I:%M %p #{?pane_in_mode,#[fg=${theme.bg}#,bg=${theme.tmuxStatusMode}#,bold],#[fg=${theme.bg}#,bg=${theme.tmuxStatusSSH}#,bold]} #H ";
  tmux-startup = pkgs.writeShellApplication {
    name = "tmux-startup";
    # Don't put tmux in runtimeInputs because that PATH is exported to every tmux shell
    runtimeInputs = [ ];
    text = # sh
      ''
        tmux new-session -As config -c "$HOME/.config/nixflake"
      '';
  };
  tmux-session-skip = pkgs.writeShellApplication {
    name = "tmux-session-skip";
    runtimeInputs = [ ];
    text = # sh
      ''
        set -x

        direction="''${1:-next}"  # Default to "next" if no argument provided

        sessions=$(tmux list-sessions -F '#{session_name}')
        current_session=$(tmux display-message -p '#{session_name}')

        # Convert to array
        readarray -t session_array <<< "$sessions"

        # Find current session index
        for i in "''${!session_array[@]}"; do
          if [[ "''${session_array[$i]}" == "$current_session" ]]; then
            if [[ "$direction" == "next" ]]; then
              # Next session: move forward, wrap around
              next_index=$(( (i + 1) % ''${#session_array[@]} ))
            elif [[ "$direction" == "prev" ]]; then
              # Previous session: move backward, wrap around
              next_index=$(( (i - 1 + ''${#session_array[@]}) % ''${#session_array[@]} ))
            else
              echo "Invalid direction: $direction. Use 'next' or 'prev'."
              exit 1
            fi

            tmux switch-client -t "''${session_array[$next_index]}"
            break
          fi
        done
      '';
  };
in
{
  home.packages = [ tmux-startup ];
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    prefix = "M-a";
    secureSocket = true; # Careful, this will mess with tmux-resurrect
    plugins = [
      pkgs.tmuxPlugins.yank
      {
        plugin = pkgs.tmuxPlugins.tmux-thumbs;
        extraConfig = ''
          set -g @thumbs-key f
          # Try to copy to every clipboard just to keep the command string simple
          set -g @thumbs-command 'tmux set-buffer -- {}; echo -n {} | ${
            if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy"
          }'
          set -g @thumbs-upcase-command '${if pkgs.stdenv.isDarwin then "open" else "xdg-open"} {}'
          set -g @thumbs-unique enabled
          set -g @thumbs-contrast 1
          set -g @thumbs-fg-color '${theme.blue}'
          set -g @thumbs-bg-color '${theme.bg2}'
          set -g @thumbs-select-fg-color '${theme.green}'
          set -g @thumbs-select-bg-color '${theme.bg2}'
          set -g @thumbs-hint-fg-color '${theme.bg2}'
          set -g @thumbs-hint-bg-color '${theme.yellow}'
          set -g @thumbs-position off_left
        '';
      }
    ];
    extraConfig = ''
      #########################################################################
      # KEYBINDINGS

      bind -n M-h if-shell -F "#{pane_at_left}" { previous-window } { select-pane -L }
      bind -n M-l if-shell -F "#{pane_at_right}" { next-window } { select-pane -R }
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-H previous-window
      bind -n M-L next-window
      bind -n M-J run-shell ${tmux-session-skip}/bin/tmux-session-skip
      bind -n M-K run-shell ${tmux-session-skip}/bin/tmux-session-skip prev
      bind -n M-Q kill-pane
      bind -n M-s choose-tree -s
      bind -n M-w choose-window -w
      bind -n M-e next-layout
      bind -n M-S command-prompt 'new-session -s %% -c ~'
      # Doesn't work on MacOS/kitty
      # bind -n M-S-tab
      bind -n M-tab switch-client -l
      bind -n M-t new-window -a -c "#{pane_current_path}"
      bind -n M-r command-prompt 'rename-window %%'
      bind -n M-R command-prompt 'rename-session %%'
      bind -n M-c source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      bind -n M-space copy-mode
      bind -n M-x split-window -v -c "#{pane_current_path}"
      bind -n M-v split-window -h -c "#{pane_current_path}"
      bind -n M-< swap-window -d -t -1
      bind -n M-> swap-window -d -t +1
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9
      bind -n M-right resize-pane -R 1
      bind -n M-left resize-pane -L 1
      bind -n M-up resize-pane -U 1
      bind -n M-down resize-pane -D 1
      bind -n M-n next-layout
      bind -n M-f thumbs-pick

      #########################################################################
      # BEHAVIOR

      # Use default-command instead of default-shell to avoid unwanted login shell behavior
      # Also don't prefix command with exec because it causes tmux-resurrect restore.sh to crash
      set -g default-command ${pkgs.zsh}/bin/zsh
      # Fixes tmux/neovim escape input lag: https://github.com/neovim/neovim/wiki/FAQ#esc-in-tmux-or-gnu-screen-is-delayed
      set -sg escape-time 10
      set -g focus-events on
      set -g renumber-windows on
      set -g update-environment "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK I3SOCK NIRI_SOCKET DISPLAY SSH_CONNECTION SSH_TTY SSH_CLIENT"
      set -g status on
      set -g status-interval 5
      set -g history-limit 8000
      set -g detach-on-destroy off # Switch to another session when last shell is closed
      set -sa terminal-features ',foot:RGB,xterm-256color:RGB,tmux-256color:RGB'
      setenv -g COLORTERM truecolor
      # If I'm using kitty, the term needs to be xterm-kitty in order for fingers to work right
      if '[ "$TERM" = "xterm-kitty" ]' { set -g default-terminal "xterm-kitty" } { set -g default-terminal "tmux-256color" }

      #########################################################################
      # APPEARANCE

      # More robust SSH detection

      set -g status-justify left
      set -g status-style bg=${theme.bg1},fg=${theme.fg}
      set -g pane-border-style bg=default,fg=${theme.bg}
      set -g pane-active-border-style bg=default,fg=${theme.blue}
      set -g pane-border-indicators arrows
      set -g display-panes-colour black
      set -g display-panes-active-colour black
      set -g clock-mode-colour '${theme.tmuxStatusMode}'
      set -g message-style bg=${theme.bg},fg=${theme.tmuxStatusNormal}
      set -g message-command-style bg=${theme.bg},fg=${theme.tmuxStatusNormal}
      set -g status-left "#(if [ -n \"$SSH_TTY\" ]; then echo '${status-left-ssh}'; else echo '${status-left-normal}'; fi)"
      set -g status-left-length 25
      set -g status-right "#(if [ -n \"$SSH_TTY\" ]; then echo '${status-right-ssh}'; else echo '${status-right-normal}'; fi)"
      set -g status-right-length 50
      set -g window-status-format "#[fg=${theme.bg4},bg=${theme.bg1}] #I #W #F "
      set -g window-status-current-format "#[fg=${theme.fg},bg=${theme.bg2}] #I #W #F "
      set -g window-status-separator ""
      set -g mode-style "fg=${theme.fg},bg=${theme.bg2}"
    '';
  };
}

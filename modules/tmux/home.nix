{ pkgs, config, ... }:
# For images in the terminal, use img2sixel from pkgs.libsixel
let
  theme = config.theme.set;
in
{
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
          set -g @thumbs-command 'tmux set-buffer -- {}; echo -n {} | ${if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy"}'
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

      # tmux doesn't have an option to avoid wrapping around with select-pane :(
      bind -n M-h select-pane -L
      bind -n M-l select-pane -R
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-H previous-window
      bind -n M-L next-window
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
      set -g update-environment "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK I3SOCK NIRI_SOCKET DISPLAY"
      set -g status on
      set -g status-interval 1
      set -g history-limit 8000
      set -g detach-on-destroy off # Switch to another session when last shell is closed
      set -sa terminal-features ',foot:RGB,xterm-256color:RGB,tmux-256color:RGB'
      setenv -g COLORTERM truecolor
      # If I'm using kitty, the term needs to be xterm-kitty in order for fingers to work right
      if '[ "$TERM" = "xterm-kitty" ]' { set -g default-terminal "xterm-kitty" } { set -g default-terminal "tmux-256color" }

      #########################################################################
      # APPEARANCE

      set -g status-justify left
      set -g status-style bg=${theme.bg1},fg=${theme.fg}
      set -g pane-border-style bg=default,fg=${theme.bg}
      set -g pane-active-border-style bg=default,fg=${theme.blue}
      set -g pane-border-indicators arrows
      set -g display-panes-colour black
      set -g display-panes-active-colour black
      set -g clock-mode-colour '${theme.tmuxPrimary}'
      set -g message-style bg=${theme.bg},fg=${theme.tmuxPrimary}
      set -g message-command-style bg=${theme.bg},fg=${theme.tmuxPrimary}
      set -g status-left "#{?pane_in_mode,#[fg=${theme.bg}#,bg=${theme.tmuxSecondary}#,bold],#[fg=${theme.bg}#,bg=${theme.tmuxPrimary}#,bold]} #S "
      set -g status-left-length 25
      set -g status-right "#{?client_prefix,#[fg=${theme.bg}#,bg=${theme.tmuxPrimary}] M-a ,}#[fg=${theme.bg4},bg=${theme.bg2}] %I:%M %p #{?pane_in_mode,#[fg=${theme.bg}#,bg=${theme.tmuxSecondary}#,bold],#[fg=${theme.bg}#,bg=${theme.tmuxPrimary}#,bold]} #H "
      set -g status-right-length 50
      set -g window-status-format "#[fg=${theme.bg4},bg=${theme.bg1}] #I #W #F "
      set -g window-status-current-format "#[fg=${theme.fg},bg=${theme.bg2}] #I #W #F "
      set -g window-status-separator ""
      set -g mode-style "fg=${theme.fg},bg=${theme.bg2}"
    '';
  };
}

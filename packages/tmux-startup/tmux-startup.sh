if tmux run &>/dev/null; then
  tmux new-session -As sandbox
else
  tmux new-session -ds config -c "$HOME/.config/nixflake"
  tmux new-session -ds media
  tmux new-session -As sandbox
fi

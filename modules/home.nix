{ inputs, ... }:
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
    inputs.agenix.homeManagerModules.default

    ./common/home.nix
    ./neovim/home.nix
    ./tmux/home.nix
    ./graphical/home.nix
    ./sway/home.nix
    ./audio/home.nix
  ];
}

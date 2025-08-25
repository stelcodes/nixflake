{ pkgs, ... }:
{
  profile = {
    graphical = true;
    battery = true;
    virtualHost = false;
    audio = true;
    bluetooth = true;
    physical = true;
  };
  activities = {
    coding = true;
    djing = true;
  };
  home = {
    username = "stel";
    homeDirectory = "/Users/stel";
    stateVersion = "24.05"; # Please read the comment before changing.
    packages = [
      # pkgs.coreutils-prefixed # coreutils for MacOS prefixed with 'g'
      # pkgs.audacity
      # pkgs.jellyfin-media-player not currently available for M1 :( have to get it from brew
    ];
  };
  programs = {
    fish.shellAbbrs.rebuild = "home-manager switch --flake \"$HOME/.config/nixflake#marlene\"";
    zsh.zsh-abbr.abbreviations.rebuild = "home-manager switch --flake \"$HOME/.config/nixflake#marlene\"";
  };

  # brew install --cask obsidian kitty syncthing calibre discord firefox gimp musescore protonvpn signal spotify zoom visual-studio-code
}

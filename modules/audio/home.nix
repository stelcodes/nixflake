{
  pkgs,
  lib,
  config,
  ...
}:
{

  home.packages = lib.mkIf config.profile.audio [
    pkgs.ffmpeg
    pkgs.convert-audio
    pkgs.rekordbox-add
  ];

}

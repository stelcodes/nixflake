{
  writeShellApplication,
  ffmpeg,
  coreutils,
  trash-cli,
}:
writeShellApplication {
  name = "rekordbox-add";
  runtimeInputs = [
    ffmpeg
    coreutils
    trash-cli
  ];
  text = builtins.readFile ./rekordbox-add.sh;
}

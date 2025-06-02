{
  writeShellApplication,
  ffmpeg,
  coreutils,
  fzf,
  trash-cli,
}:
writeShellApplication {
  name = "convert-audio";
  runtimeInputs = [
    ffmpeg
    coreutils
    fzf
    trash-cli
  ];
  text = builtins.readFile ./convert-audio.sh;
}

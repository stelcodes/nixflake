{
  direnv,
  git,
  gh,
  nix,
  writeShellApplication,
}:
writeShellApplication {
  name = "devflake";
  runtimeInputs = [
    git
    gh
    direnv
    nix
  ];
  text = builtins.readFile ./devflake.sh;
}

{
  coreutils-full,
  procps,
  hostname,
  gnused,
  tmux,
  tmuxPlugins,
  gnugrep,
  gnutar,
  gzip,
  findutils,
  writeShellApplication,
  replaceVars,
}:
writeShellApplication {
  name = "tmux-snapshot";
  runtimeInputs = [
    coreutils-full
    procps
    hostname
    gnused
    tmux
    gnugrep
    gnutar
    gzip
    findutils
  ];
  text = replaceVars ./tmux-snapshot.sh {
    tmux_resurrect = builtins.toString tmuxPlugins.resurrect;
  };
}

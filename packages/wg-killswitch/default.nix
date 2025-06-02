{
  iptables,
  coreutils-full,
  wireguard-tools,
  writeShellApplication,
}:
writeShellApplication {
  name = "wg-killswitch";
  runtimeInputs = [
    wireguard-tools
    iptables
    coreutils-full
  ];
  text = builtins.readFile ./wg-killswitch.sh;
}

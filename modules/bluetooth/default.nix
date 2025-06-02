{
  pkgs,
  config,
  lib,
  ...
}:
{

  config = lib.mkIf config.profile.bluetooth {

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

  };
}

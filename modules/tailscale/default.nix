{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Check to make sure this is all still valid before using
  config = lib.mkIf config.services.tailscale.enable {
    # services.tailscale.enable = true;
    environment.systemPackages = [ pkgs.tailscale ];
    networking.firewall = {
      # enable the firewall
      enable = true;
      # always allow traffic from your Tailscale network
      trustedInterfaces = [ "tailscale0" ];
      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
      # allow you to SSH in over the public internet
      allowedTCPPorts = [ 22 ];
    };
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      # make sure tailscale is running before trying to connect to tailscale
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = [ "multi-user.target" ];
      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";
      # have the job run this shell script
      script = ''
        # wait for tailscaled to settle
        sleep 2
        # check if we are already authenticated to tailscale
        status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi
        # otherwise authenticate with tailscale
        ${pkgs.tailscale}/bin/tailscale up -authkey 'file:${config.age.secrets.tailscale-auth-key.path}'
      '';
    };
  };
}

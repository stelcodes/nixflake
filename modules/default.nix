{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.nixos-generators.nixosModules.all-formats

    ./common
    ./graphical
    ./battery
    ./audio
    ./bluetooth
    ./virtualisation
    ./pam-parallel
    ./postgresql
    ./physical
  ];

}

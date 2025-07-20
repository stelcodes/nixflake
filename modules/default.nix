{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

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

  config.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      systemConfig = config;
    };
    backupFileExtension = "backup";
    users.${config.admin.username} = {
      imports = [
        ./home.nix
        ../hosts/${config.networking.hostName}/home.nix
      ];
      config = {
        inherit (config) activities profile theme admin;
      };
    };
  };

}

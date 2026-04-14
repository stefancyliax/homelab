{
  description = "Homelab NixOS Hive";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    colmena.url = "github:zhaofengli/colmena/stable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    comin.url = "github:nlewo/comin";
  };

  outputs = { self, nixpkgs, colmena, agenix, comin }: 
  let
    # Reusable baseline for all cluster nodes
    baseModules = [
      { system.configurationRevision = self.rev or self.dirtyRev or null; }
      agenix.nixosModules.default
      comin.nixosModules.comin
      ./modules/comin.nix
    ];
  in {

    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        description = "Homelab NixOS Hive";
      };

      defaults = { pkgs, ... }: {
        imports = baseModules;
        deployment = {
          targetUser = "stefan";
          privilegeEscalationCommand = [ "sudo" "-S" "-p" "''" "--" ];
        };
      };

      infra-node = { name, nodes, pkgs, ... }: {
        deployment.targetHost = "10.1.23.184";
        imports = [ 
          ./nodes/infra-node/configuration.nix 
          ./modules/dockhand.nix
        ];
      };

      services-node = { name, nodes, pkgs, ... }: {
        deployment.targetHost = "10.1.23.224";
        imports = [ 
          ./nodes/services-node/configuration.nix 
          ./modules/hawser.nix
        ];
      };

      another-node = { name, nodes, pkgs, ... }: {
        deployment.targetHost = "10.1.23.165";
        imports = [ 
          ./nodes/another-node/configuration.nix 
          ./modules/hawser.nix
        ];
      };
    };

    nixosConfigurations = {
      "infra-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/infra-node/configuration.nix 
          ./modules/dockhand.nix
        ];
      };

      "services-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/services-node/configuration.nix 
          ./modules/hawser.nix
        ];
      };

      "another-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/another-node/configuration.nix 
          ./modules/hawser.nix
        ];
      };

      "comin-test" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/comin-test/configuration.nix
        ];
      };

    };
  };
}
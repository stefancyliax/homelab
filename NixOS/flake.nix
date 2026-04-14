{
  description = "Homelab NixOS Hive";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    colmena.url = "github:zhaofengli/colmena/stable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    comin.url = "github:nlewo/comin";
  };

  outputs = { self, nixpkgs, colmena, agenix, comin }: {

    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        description = "Homelab NixOS Hive";
      };

      defaults = { pkgs, ... }: {
        imports = [ agenix.nixosModules.default ];
        system.configurationRevision = self.rev or self.dirtyRev or null;
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

      # gpu-worker = { name, nodes, pkgs, ... }: {
      #   deployment.targetHost = "10.1.23.247";
      #   imports = [ ./nodes/gpu-worker/configuration.nix ];
      # };
    };

    nixosConfigurations = {
      # We define comin-test here instead of colmenaHive so that Comin pulls it naturally,
      # but Colmena ignores it when pushing.
      "comin-test" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          { system.configurationRevision = self.rev or self.dirtyRev or null; }
          ./nodes/comin-test/configuration.nix
          agenix.nixosModules.default
          comin.nixosModules.comin
        ];
      };
    };

    # # Optional: nix develop to get colmena in your shell
    # devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
    #   packages = [ colmena.packages.aarch64-darwin.colmena ];    
    # };
  };
}
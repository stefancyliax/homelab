{
  description = "Homelab NixOS Hive";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    colmena.url = "github:zhaofengli/colmena/stable";
  };

  outputs = { self, nixpkgs, colmena }: {

    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        description = "Homelab NixOS Hive";
      };

      defaults = { pkgs, ... }: {
        deployment = {
          targetUser = "stefan";
          privilegeEscalationCommand = [ "sudo" "-S" "-p" "''" "--" ];
        };
      };

      infra-stack = { name, nodes, pkgs, ... }: {
        deployment.targetHost = "10.1.23.240";
        imports = [ ./nodes/infra-stack/configuration.nix ];
      };

      services-stack = { name, nodes, pkgs, ... }: {
        deployment.targetHost = "10.1.23.36";
        imports = [ ./nodes/services-stack/configuration.nix ];
      };

      another-test = { name, nodes, pkgs, ... }: {
        deployment.targetHost = "10.1.23.242";
        imports = [ ./nodes/another-test/configuration.nix ];
      };
    };

    # # Optional: nix develop to get colmena in your shell
    # devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
    #   packages = [ colmena.packages.aarch64-darwin.colmena ];    
    # };
  };
}
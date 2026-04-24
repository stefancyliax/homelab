{
  description = "Homelab NixOS Hive";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    comin.url = "github:nlewo/comin";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix, comin }:
  let
    # Import unstable nixpkgs for packages that need bleeding-edge versions
    pkgs-unstable = import nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    # Reusable baseline for all cluster nodes
    baseModules = [
      { system.configurationRevision = self.rev or self.dirtyRev or null; }
      agenix.nixosModules.default
      comin.nixosModules.comin
      ./modules/comin.nix
    ];
  in {

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

      
      "gpu-worker" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs-unstable; };
        modules = baseModules ++ [
          ./nodes/gpu-worker/configuration.nix 
          ./modules/llama-swap.nix
          ./modules/hawser.nix
        ];
      };

      "ollama-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs-unstable; };
        modules = baseModules ++ [
          ./nodes/ollama-node/configuration.nix
          ./modules/ollama.nix
          ./modules/hawser.nix
        ];
      };

    };
  };
}
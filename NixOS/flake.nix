{
  description = "Homelab NixOS Hive";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Only provides the github-runner package; bumped independently of the other inputs
    nixpkgs-runner.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    comin.url = "github:nlewo/comin";
    comin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-runner, agenix, comin }:
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

      "hermes-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/hermes-node/configuration.nix
          ./modules/hermes.nix
          ./modules/syncthing.nix
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

      "runner-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { pkgs-runner = nixpkgs-runner.legacyPackages.x86_64-linux; };
        modules = baseModules ++ [
          ./nodes/runner-node/configuration.nix
          ./modules/github-runner.nix
        ];
      };

      "storage-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/storage-node/configuration.nix
          ./modules/hawser.nix
        ];
      };

      "agent-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/agent-node/configuration.nix
        ];
      };

      "agent-tools-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/agent-tools-node/configuration.nix
          ./modules/hawser.nix
        ];
      };

      "work-tools-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/work-tools-node/configuration.nix
          ./modules/hawser.nix
        ];
      };

      "frigate-node" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = baseModules ++ [
          ./nodes/frigate-node/configuration.nix
          ./modules/hawser.nix
        ];
      };

    };
  };
}
{
  meta = {
    nixpkgs = <nixpkgs>;
    description = "Homelab NixOS Hive";
  };

  defaults = { pkgs, ... }: {
    deployment = {
      targetUser = "stefan"; # Using your user as defined in configuration.nix
      # Allow using sudo for deployment
      privilegeEscalationCommand = [ "sudo" "-S" "-p" "''" "--" ];
    };
  };

  infra-stack = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.240";
    };
    imports = [ ./nodes/infra-stack/configuration.nix ];
  };

  services-stack = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.36";
    };
    imports = [ ./nodes/services-stack/configuration.nix ];
  };

  another-test = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.242";
    };
    imports = [ ./nodes/another-test/configuration.nix ];
  };

}

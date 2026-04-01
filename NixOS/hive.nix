{
  meta = {
    nixpkgs = <nixpkgs>;
    description = "Homelab NixOS Infrastructure";
  };

  defaults = { pkgs, ... }: {
    system.stateVersion = "25.11"; 

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "prohibit-password";
    };

    # Consistent SSH access for all machines
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5JMr8VHXzj9iQf17/rTYIYfbR41a73eCmxsFepUtH stefan.cyliax@gmail.com"
    ];
  };

  # The main Infrastructure & Komodo VM
  komodo-vm = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.100"; 
      targetUser = "root";
      sshOptions = [ "-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" ];
    };
    imports = [ ./nodes/komodo-vm/configuration.nix ];
  };

  # The Services VM (Managed by Komodo Core)
  services-vm = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.101"; # Replace with actual IP
      targetUser = "root";
      sshOptions = [ "-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" ];
    };
    imports = [ ./nodes/services-vm/configuration.nix ];
  };

  # The GitHub Runner VM
  github-runner-nixos = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.102"; # Replace with actual IP
      targetUser = "root";
      sshOptions = [ "-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" ];
    };
    imports = [ ./nodes/github-runner-nixos/configuration.nix ];
  };
}

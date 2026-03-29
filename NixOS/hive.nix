{
  meta = {
    # Default nixpkgs for the hive
    # You might want to pin this using a flake or a specific commit in the future.
    nixpkgs = <nixpkgs>;
    description = "Homelab NixOS Infrastructure";
  };

  defaults = { pkgs, ... }: {
    # Basic system-wide settings for all nodes
    system.stateVersion = "25.11"; 

    # Enable SSH for Colmena deployments
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "prohibit-password";
    };

    # Add your SSH public key here for initial access
    users.users.root.openssh.authorizedKeys.keys = [
     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODSyeGQIw18PlZYiV+xyjtHkSX5D87z0vkqm98uxBtn homelab-deployment" 
    ];
  };

  komodo-vm = { name, nodes, pkgs, ... }: {
    deployment = {
      targetHost = "10.1.23.245"; # REPLACE with the actual IP address of the VM
      targetUser = "root";
      sshOptions = [
        "-o" "StrictHostKeyChecking=no"
        "-o" "UserKnownHostsFile=/dev/null"
      ];
    };

    imports = [
      ./nodes/komodo-vm/configuration.nix
    ];
  };
}

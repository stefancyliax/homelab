let
  # User SSH Keys (for encrypting/decrypting secrets from your local machine)
  stefan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZtmjhoy3eeriptTopsxadZ+LbKX84W8892YEoGF5Iy";
  users = [ stefan ];

  # Machine SSH Keys (Host keys of the nodes so they can decrypt their own secrets on boot)
  infra-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjYs+UlG1KAEDQSawTdliumatYyEaCfWBEMr7ksGfMC root@nixos-base";
  services-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINRRVU8zF8sW1JZhed7j4BszcAuUpEalL+nr0ZWOntfA root@nixos-base";
  another-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7NtsOzf6BjKWZUiNFYONrm16K9GGPrtD/Z30cCqOs+ root@nixos-base";
  comin-test = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVZbdM/BB07b5K277nQtAgRQTpSOJJ2/pqVjd+2laT/ root@nixos-base";
  
  systems = [ infra-node services-node another-node comin-test ]; 
in
{
  # Example: The hawser token can be decrypted by Stefan and (eventually) the nodes that run Hawser.
  "secrets/hawser-token.age".publicKeys = users ++ systems;
  "secrets/rclone-conf.age".publicKeys = users ++ [ services-node ];
  
  # Comin deploy key, readable by the user and all systems that might run Comin
  "secrets/comin-github-pat.age".publicKeys = users ++ systems;
}

let
  # User SSH Keys (for encrypting/decrypting secrets from your local machine)
  stefan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZtmjhoy3eeriptTopsxadZ+LbKX84W8892YEoGF5Iy";
  users = [ stefan ];

  # Machine SSH Keys (Host keys of the nodes so they can decrypt their own secrets on boot)
  infra-stack = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjYs+UlG1KAEDQSawTdliumatYyEaCfWBEMr7ksGfMC root@nixos-base";
  services-stack = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINRRVU8zF8sW1JZhed7j4BszcAuUpEalL+nr0ZWOntfA root@nixos-base";
  another-test = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7NtsOzf6BjKWZUiNFYONrm16K9GGPrtD/Z30cCqOs+ root@nixos-base";
  
  systems = [ infra-stack services-stack another-test ]; 
in
{
  # Example: The hawser token can be decrypted by Stefan and (eventually) the nodes that run Hawser.
  "secrets/hawser-token.age".publicKeys = users ++ systems;
}

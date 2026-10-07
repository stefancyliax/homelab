let
  # User SSH Keys (for encrypting/decrypting secrets from your local machine)
  stefan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZtmjhoy3eeriptTopsxadZ+LbKX84W8892YEoGF5Iy";
  users = [ stefan ];

  # Machine SSH Keys (Host keys of the nodes so they can decrypt their own secrets on boot)
  infra-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjYs+UlG1KAEDQSawTdliumatYyEaCfWBEMr7ksGfMC root@nixos-base";
  services-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINRRVU8zF8sW1JZhed7j4BszcAuUpEalL+nr0ZWOntfA root@nixos-base";
  another-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7NtsOzf6BjKWZUiNFYONrm16K9GGPrtD/Z30cCqOs+ root@nixos-base";
  gpu-worker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQLhHjz+3k2fbirx8RX3vVpGzI0To7S1abDf9M22dyk root@nixos-base";
  hermes-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUVu4Tgapi7czpPHdL8jnWLXluxqfmJqkzBcs9rYvUE root@nixos-base"; 
  # Kept out of `systems`: the CI runner only needs the Comin PAT
  runner-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMkWzerz/OZieg2eiqYnRL4UO4aRxiD2XIXQrGfjWKwG root@nixos-base";
  
  # Kept out of `systems` like the runner: runs no Hawser, only needs the Comin PAT
  agent-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWjCs8EFuAJTflQqVl91Noi7r/AtPasD70vd9yx2Toh";
  storage-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOJWfTUuyHHOb6AHYpTLj6tJ9dzGLFMzTgslK5Fdr5C";
  agent-tools-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8/bila9Zj1kB1204Jv72H/bX+9j6j/6xr71+bgJ1h4";
  work-tools-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMalIA//5lvQBFDWIWVf7jbKmvf0DKpwPhxC+qIXwoHI";
  frigate-node = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrdRmrQ21s1wYCd/PmvPa5HqfEASqkyE6MB2sCGRBxh";

  systems = [ infra-node services-node another-node gpu-worker hermes-node storage-node agent-tools-node work-tools-node frigate-node ]; 
in
{
  # How this works: The hawser token can be decrypted by Stefan and (eventually) the nodes that run Hawser.
  "secrets/hawser-token.age".publicKeys = users ++ systems;
  "secrets/rclone-conf.age".publicKeys = users ++ [ services-node ];
  
  # Comin deploy key, readable by the user and all systems that might run Comin
  "secrets/github-pat.age".publicKeys = users ++ systems ++ [ runner-node agent-node ];

  # OIDC Secrets (mounted into Authelia container as files)
  "secrets/authelia-oidc-hmac.age".publicKeys = users ++ [ infra-node ];
  "secrets/authelia-oidc-rsa.age".publicKeys = users ++ [ infra-node ];
  "secrets/authelia-session-secret.age".publicKeys = users ++ [ infra-node ];
  "secrets/authelia-storage-key.age".publicKeys = users ++ [ infra-node ];
  "secrets/authelia-jwt-secret.age".publicKeys = users ++ [ infra-node ];
}
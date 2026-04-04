{ config, pkgs, ... }:

{
  # Define the secret payload file pointing to your age-encrypted file
  age.secrets.hawser-token.file = ../secrets/hawser-token.age;

  # Explicitly force the OCI engine to be Docker rather than defaulting to Podman
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.hawser = {
    image = "ghcr.io/finsys/hawser:latest";
    ports = [ "2376:2376" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "hawser_stacks:/data/stacks"
    ];
    # We reference the decrypted path via environmentFiles.
    # Note: Your decrypted secret payload MUST be formatted as exactly: TOKEN=your_secret_string
    environmentFiles = [
      config.age.secrets.hawser-token.path
    ];
  };
}

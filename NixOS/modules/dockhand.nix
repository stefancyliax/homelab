{ config, pkgs, ... }:

{
  # Explicitly force the OCI engine to be Docker for full compatibility
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.dockhand = {
    image = "fnsys/dockhand:latest";
    ports = [ "3000:3000" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "dockhand_data:/app/data"
      "/run/agenix:/run/agenix:ro" # Allows docker-compose inside dockhand to read the secrets
    ];
  };
}

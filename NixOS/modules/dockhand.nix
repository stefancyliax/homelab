{ config, pkgs, ... }:

{
  # Explicitly force the OCI engine to be Docker for full compatibility
  virtualisation.oci-containers.backend = "docker";

  # Create a dedicated docker network that both dockhand and infra-stack can use
  systemd.services.init-docker-network = {
    description = "Create infra_net Docker network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "docker-dockhand.service" ];
    script = ''
      ${pkgs.docker}/bin/docker network inspect infra_net >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create infra_net
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  virtualisation.oci-containers.containers.dockhand = {
    image = "fnsys/dockhand:latest";
    ports = [ "3000:3000" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "dockhand_data:/app/data"
      "/run/agenix:/run/agenix:ro" # Allows docker-compose inside dockhand to read the secrets
    ];
    extraOptions = [ "--network=infra_net" ];
  };
}

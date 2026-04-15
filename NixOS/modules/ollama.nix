{ config, pkgs, ... }:

{
  # Enable the native Ollama service
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
  };

  # Open-WebUI for browser-based LLM interaction
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.open-webui = {
    image = "ghcr.io/open-webui/open-webui:main";
    ports = [ "3000:8080" ];
    volumes = [
      "open-webui_data:/app/backend/data"
    ];
    environment = {
      OLLAMA_BASE_URL = "http://host.docker.internal:11434";
    };
    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
  };

  # Open firewall for Open-WebUI
  networking.firewall.allowedTCPPorts = [ 3000 ];
}

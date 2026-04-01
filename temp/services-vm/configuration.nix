{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "services-vm";

  # Enable Docker
  virtualisation.docker.enable = true;

  # Run Komodo Periphery only
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers."komodo-periphery" = {
    image = "ghcr.io/moghtech/komodo-periphery:latest";
    ports = [ "8120:8120" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/var/lib/komodo-periphery:/etc/komodo"
    ];
    environment = {
      # PERIPHERY_CORE_ADDRESS = "http://10.1.23.100:9120"; # Point to the Infra VM
    };
  };

  networking.firewall.allowedTCPPorts = [ 8120 ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; 

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    vim git htop curl
  ];
}

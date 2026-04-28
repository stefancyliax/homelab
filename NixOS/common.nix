{ config, pkgs, ... }:

{
  # Networking
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "UTC";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable Docker daemon
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon.settings = {
      metrics-addr = "0.0.0.0:9323";
    };
  };

  # Enable the QEMU Guest Agent
  services.qemuGuest.enable = true;

  # Enable Prometheus Node Exporter
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    port = 9100;
  };

  # Open Docker metrics port
  networking.firewall.allowedTCPPorts = [ 9323 ];

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    docker-compose
    yazi
    btop
  ];

  # User Configuration ("stefan")
  users.users.stefan = {
    isNormalUser = true;
    description = "Stefan";
    extraGroups = [ "wheel" "docker" ];
    hashedPassword = "!"; 
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZtmjhoy3eeriptTopsxadZ+LbKX84W8892YEoGF5Iy" 
    ];
  };

  # Configure passwordless sudo specifically for the user "stefan"
  security.sudo.extraRules = [
    {
      users = [ "stefan" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Enable SSH and disable password auth over the network
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Allow the deployment user to push unsigned closures
  nix.settings.trusted-users = [ "root" "stefan" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11"; 
}

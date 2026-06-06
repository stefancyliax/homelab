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

  # Enable Promtail for Log Shipping
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/var/lib/promtail/positions.yaml";
      };
      clients = [{
        url = "http://10.1.23.184:3100/loki/api/v1/push";
      }];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
            {
              source_labels = ["__journal__hostname"];
              target_label = "host";
            }
            {
              source_labels = ["__journal_priority_keyword"];
              target_label = "level";
            }
          ];
        }
        {
          job_name = "docker";
          static_configs = [{
            targets = ["localhost"];
            labels = {
              job = "docker";
              __path__ = "/var/lib/docker/containers/*/*-json.log";
            };
          }];
          pipeline_stages = [{
            docker = {};
          }];
        }
      ];
    };
  };

  # Open Docker metrics and Promtail ports
  networking.firewall.allowedTCPPorts = [ 9323 9080 ];

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    docker-compose
    yazi
    btop
    tldr
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
  nix.settings.auto-optimise-store = true;

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "25.11"; 
}

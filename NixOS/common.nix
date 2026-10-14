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

  # Enable Grafana Alloy for Log Shipping (replaces Promtail, removed in nixos-26.05)
  services.alloy.enable = true;
  # Read container logs through the Docker socket (the log files under /var/lib/docker are root-only)
  systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "docker" ];
  environment.etc."alloy/config.alloy".text = ''
    loki.write "default" {
      endpoint {
        url = "http://10.1.23.184:3100/loki/api/v1/push"
      }
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal__hostname"]
        target_label  = "host"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
    }

    loki.source.journal "journal" {
      max_age       = "12h"
      labels        = { job = "systemd-journal" }
      relabel_rules = loki.relabel.journal.rules
      forward_to    = [loki.write.default.receiver]
    }

    discovery.docker "containers" {
      host = "unix:///var/run/docker.sock"
    }

    discovery.relabel "docker" {
      targets = []

      rule {
        source_labels = ["__meta_docker_container_name"]
        regex         = "/(.*)"
        target_label  = "container"
      }
    }

    loki.source.docker "docker" {
      host          = "unix:///var/run/docker.sock"
      targets       = discovery.docker.containers.targets
      labels        = { job = "docker", host = constants.hostname }
      relabel_rules = discovery.relabel.docker.rules
      forward_to    = [loki.write.default.receiver]
    }
  '';

  # Open Docker metrics port
  networking.firewall.allowedTCPPorts = [ 9323 ];

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

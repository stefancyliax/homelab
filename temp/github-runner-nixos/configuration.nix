# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "github-runner-nixos"; 
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.stefan = {
    isNormalUser = true;
    description = "stefan";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5JMr8VHXzj9iQf17/rTYIYfbR41a73eCmxsFepUtH stefan.cyliax@gmail.com" ];
    packages = with pkgs; [];
  };
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.runner = {
    isNormalUser = true;
    description = "github runner";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODSyeGQIw18PlZYiV+xyjtHkSX5D87z0vkqm98uxBtn homelab-deployment" ];
    packages = with pkgs; [];
  };

  # 1. Create a file to hold your token (do not commit this to git!)
  # echo "YOUR_TOKEN_HERE" > /var/lib/github-runner/token
  # chown root:root /var/lib/github-runner/token
  # chmod 600 /var/lib/github-runner/token

  services.github-runners.my-nixos-runner = {
    enable = true;
    url = "https://github.com/stefancyliax/homelab"; # Use org URL for org-wide runners
    tokenFile = "/var/lib/github-runner/token";
    
    # Optional: Add extra packages available to the runner
    extraPackages = with pkgs; [
      git
      docker
      nodejs
      nix
      colmena
      openssh
      curl
      wget
    ];

    # Optional: Labels to help GitHub identify this runner
    extraLabels = [ "nixos" "infra" ];
  };


  nix.settings.trusted-users = [ "root" "runner" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim 
    wget
    curl
  ];

  # Enable Docker
  # virtualisation.docker.enable = true;

  # # Enable the Komodo Periphery agent for self-management
  # services.komodo-periphery = {
  #   enable = true;
  #   # Ensure Docker is accessible to Komodo
  #   environment = {
  #     DOCKER_HOST = "unix:///var/run/docker.sock";
  #   };
  # };

  # # Deploy Komodo Core (Dashboard) as an OCI container
  # virtualisation.oci-containers.backend = "docker";
  # virtualisation.oci-containers.containers."komodo-core" = {
  #   image = "ghcr.io/moghtech/komodo-core:latest";
  #   ports = [ "9120:9120" ];
  #   volumes = [
  #     "/var/lib/komodo/config:/config"
  #     "/var/lib/komodo/data:/data"
  #     "/var/run/docker.sock:/var/run/docker.sock" # Allow Komodo to manage local containers
  #   ];
  #   environment = {
  #     KOMODO_HTTP_PORT = "9120";
  #   };
  # };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

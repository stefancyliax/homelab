{ config, pkgs, ... }:

{

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  
  # ==========================================
  # System Packages & Virtualisation
  # ==========================================
  
  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;


  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "UTC";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable Docker daemon
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Enable the QEMU Guest Agent
  services.qemuGuest.enable = true;
  
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    docker-compose
  ];

  # ==========================================
  # User Configuration ("stefan")
  # ==========================================
  
  users.users.stefan = {
    isNormalUser = true;
    description = "Stefan";
    
    # Add to wheel for sudo, and docker to run containers without sudo
    extraGroups = [ "wheel" "docker" ];
    
    # Setting this to "!" disables password-based logins, enforcing passkeys
    hashedPassword = "!"; 
    
    # [Option A: Remote SSH Passkey]
    # If your passkey is an SSH key (e.g., standard ed25519 or FIDO2 hardware key):
    openssh.authorizedKeys.keys = [
      # Replace this with your actual public key string
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZtmjhoy3eeriptTopsxadZ+LbKX84W8892YEoGF5Iy" 
    ];
  };

  # ==========================================
  # Security & Privilege Escalation
  # ==========================================

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
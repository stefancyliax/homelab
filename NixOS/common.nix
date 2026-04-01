{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

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
  };

  # Enable the QEMU Guest Agent
  services.qemuGuest.enable = true;
  
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    docker-compose
    fzf
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

  system.stateVersion = "25.11"; 
}

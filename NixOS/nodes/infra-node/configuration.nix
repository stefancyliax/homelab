{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "infra-node";

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable IP forwarding for Tailscale subnet router
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Decrypt OIDC secrets for Authelia (mounted into the container via docker-compose)
  age.secrets."authelia-oidc-hmac" = { file = ../../secrets/authelia-oidc-hmac.age; mode = "0444"; };
  age.secrets."authelia-oidc-rsa" = { file = ../../secrets/authelia-oidc-rsa.age; mode = "0444"; };
}

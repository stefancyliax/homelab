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

  # Decrypt the environment variables for the infra-stack
  age.secrets."infra-env".file = ../../secrets/infra-env.age;
}

{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "hermes-node";

  # Enable Tailscale for secure access to GPU-Worker
  services.tailscale.enable = true;

  nixpkgs.config.allowUnfree = true;
}

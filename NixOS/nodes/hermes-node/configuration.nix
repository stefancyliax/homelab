{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # Bootloader (UEFI — new VM convention)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "hermes-node";

  # Enable Tailscale for secure access to GPU-Worker
  services.tailscale.enable = true;

  nixpkgs.config.allowUnfree = true;
}

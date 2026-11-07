{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
    ../../modules/intel-igpu.nix # Iris Xe from phil, for Frigate
  ];

  # Bootloader (OVMF/UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "frigate-node";
}

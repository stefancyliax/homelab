{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
  ];

  # Bootloader (OVMF/UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "storage-node";

  # Data root served by NextExplorer. Lives on the VM disk until the HDDs are passed through.
  systemd.tmpfiles.rules = [
    "d /mnt/data 0755 stefan users -"
  ];
}

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

  networking.hostName = "runner-node";

  # A job that outgrows the RAM must not freeze the VM: without swap the kernel thrashes
  # on its page cache instead of killing anything. zram gives it room to breathe and
  # earlyoom kills the largest process before the system stops responding.
  zramSwap.enable = true;
  services.earlyoom.enable = true;
}

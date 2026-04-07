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

  # Decrypt the rclone configuration file
  age.secrets."rclone-conf".file = ../../secrets/rclone-conf.age;
  # Optionally, symlink it to a common location so rclone or systemd can easily find it
  environment.etc."rclone/rclone.conf".source = config.age.secrets."rclone-conf".path;
}

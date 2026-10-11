{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
  ];

  # Bootloader (OVMF/UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "agent-node";

  # Garage S3 write key for the `artifacts` bucket: an AWS credentials file with a
  # [garage] profile, which is where the publish-s3 skill looks for it
  age.secrets.garage-agent-node-key = {
    file = ../../secrets/garage-agent-node-key.age;
    path = "/home/stefan/.aws/credentials";
    owner = "stefan";
    group = "users";
  };

  # Agenix creates the parent directory as root; hand it to stefan
  systemd.tmpfiles.rules = [
    "d /home/stefan/.aws 0700 stefan users -"
  ];
}

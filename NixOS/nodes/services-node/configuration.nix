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

  networking.hostName = "services-node";

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/6e1823cc-4e89-4901-ad18-546f28cefc37";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  # Declaratively ensure the mount point is owned by the main user
  systemd.tmpfiles.rules = [
    "d /mnt/data 0755 stefan users -"
  ];

  # Decrypt the rclone configuration file
  age.secrets."rclone-conf".file = ../../secrets/rclone-conf.age;
  # Optionally, symlink it to a common location so rclone or systemd can easily find it
  environment.etc."rclone/rclone.conf".source = config.age.secrets."rclone-conf".path;

  # Enable Samba Server for the Paperless consume hot-folder
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "services-node";
        "netbios name" = "services-node";
        "security" = "user";
        "map to guest" = "bad user";
      };
      "paperless-consume" = {
        "path" = "/home/stefan/paperless-consume";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "stefan";
        "force group" = "users";
      };
    };
  };

  # Make the Samba share discoverable natively on macOS/Windows (WSDD)
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}

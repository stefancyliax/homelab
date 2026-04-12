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

  # Enable NFS Server for the Paperless consume hot-folder
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /home/stefan/paperless-consume  10.1.23.0/24(rw,sync,insecure,no_subtree_check,all_squash,anonuid=1000,anongid=100)
  '';

  # Open the firewall for NFS (including macOS discovery ports like rpcbind)
  networking.firewall.allowedTCPPorts = [ 111 2049 20048 ];
  networking.firewall.allowedUDPPorts = [ 111 2049 20048 ];
}

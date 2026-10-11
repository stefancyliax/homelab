{ config, pkgs, ... }:

{
  # Created with `openssl rand -hex 32`; root reads it too, so `sudo garage ...` works on the node
  age.secrets.garage-rpc-secret = {
    file = ../secrets/garage-rpc-secret.age;
    owner = "garage";
    group = "garage";
  };

  # SATA SSD, passed through whole from vault (see docs/proxmox-setup.md).
  # Mounted by label, so the config does not depend on the disk's UUID.
  # nofail: the node still boots (and Comin still deploys) if the disk is missing.
  fileSystems."/mnt/garage" = {
    device = "/dev/disk/by-label/garage-data";
    fsType = "xfs";
    options = [ "noatime" "nofail" "x-systemd.device-timeout=10s" ];
  };

  # Static user instead of the module's DynamicUser, so it can own the data directory on the SSD
  users.users.garage = {
    isSystemUser = true;
    group = "garage";
  };
  users.groups.garage = { };

  systemd.tmpfiles.rules = [
    "d /mnt/garage/data 0750 garage garage -"
  ];

  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    settings = {
      # Single node, dev use: no redundancy
      replication_factor = 1;
      db_engine = "lmdb";

      # Metadata on the VM disk (NVMe), data on the SSD
      metadata_dir = "/var/lib/garage/meta";
      data_dir = "/mnt/garage/data";

      rpc_bind_addr = "127.0.0.1:3901";
      rpc_public_addr = "127.0.0.1:3901";
      rpc_secret_file = config.age.secrets.garage-rpc-secret.path;

      s3_api = {
        api_bind_addr = "[::]:3900";
        s3_region = "garage";
      };

      # Website buckets: the bucket is picked by the Host header,
      # so artifacts.home.stefancyliax.de serves the bucket `artifacts`
      s3_web = {
        bind_addr = "[::]:3902";
        root_domain = ".home.stefancyliax.de";
        index = "index.html";
      };

      admin.api_bind_addr = "127.0.0.1:3903";
    };
  };

  systemd.services.garage = {
    # Never start on the bare mount point: Garage would write to the VM disk
    unitConfig.RequiresMountsFor = [ "/mnt/garage" ];
    serviceConfig = {
      DynamicUser = false;
      User = "garage";
      Group = "garage";
    };
  };

  # S3 API and website endpoint, reached by Caddy on infra-node
  networking.firewall.allowedTCPPorts = [ 3900 3902 ];
}

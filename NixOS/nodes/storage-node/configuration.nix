{ config, pkgs, ... }:

let
  # Report a scrub result to ntfy. Runs as ExecStopPost, so also when the scrub fails
  # or is cancelled (e.g. by a shutdown): a missing message means the scrub never ran.
  scrubNotify = fs: toString (pkgs.writeShellScript "btrfs-scrub-notify" ''
    status=$(${pkgs.btrfs-progs}/bin/btrfs scrub status ${fs} 2>&1)
    if echo "$status" | ${pkgs.gnugrep}/bin/grep -q "Status:.*aborted"; then
      title="Scrub cancelled"; priority=default; tags=warning
    elif [ "$SERVICE_RESULT" = success ] && echo "$status" | ${pkgs.gnugrep}/bin/grep -q "no errors found"; then
      title="Scrub passed"; priority=low; tags=white_check_mark
    else
      title="❌ Scrub found errors"; priority=high; tags=x
    fi
    ${pkgs.curl}/bin/curl -s --max-time 10 \
      -H "Title: $title: ${config.networking.hostName} ${fs}" \
      -H "Tags: $tags" \
      -H "Priority: $priority" \
      --data-binary "$status" \
      http://10.1.23.184:2586/homelab-alerts || true
  '');
in
{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
  ];

  # Bootloader (OVMF/UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "storage-node";

  # Intel UHD 770, passed through from vault (see docs/proxmox-setup.md).
  # i915 needs the GuC/HuC/DMC blobs; the qemu-guest profile ships no firmware.
  hardware.enableRedistributableFirmware = true;

  # VAAPI driver on the VM itself, only to validate the passthrough with vainfo.
  # Jellyfin brings its own driver stack in the container and just needs /dev/dri.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  # i915 creates the render node late in boot, and Docker gives up on a container whose
  # device is missing instead of retrying, so Jellyfin stayed down after a reboot. Expose
  # the node as a systemd device unit and start Docker only once it exists. Wants (not
  # Requires): if the passthrough is gone, Docker still starts after the device timeout.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD128", TAG+="systemd"
  '';
  # The same for the HDDs: a container started before its disk is mounted would bind the
  # empty directory underneath and write to the VM disk.
  systemd.services.docker = {
    wants = [ "dev-dri-renderD128.device" "mnt-data.mount" "mnt-backup.mount" ];
    after = [ "dev-dri-renderD128.device" "mnt-data.mount" "mnt-backup.mount" ];
  };

  environment.systemPackages = with pkgs; [
    pciutils        # lspci
    intel-gpu-tools # intel_gpu_top
    libva-utils     # vainfo
  ];

  # Data root served by NextExplorer, and the backup disk, which for now also holds the
  # media library Jellyfin reads.
  systemd.tmpfiles.rules = [
    "d /mnt/data 0755 stefan users -"
    "d /mnt/backup 0755 stefan users -"
  ];

  # HDDs passed through by-id from vault, btrfs so that a scrub reveals which file went
  # bad. nofail: a missing disk must not block the boot.
  # 6 TB Seagate: bulk storage, media and general shares.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "noatime" "nofail" ];
  };
  # 2 TB WD Red: local backup copy of the important shares.
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-label/backup";
    fsType = "btrfs";
    options = [ "noatime" "nofail" ];
  };
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/mnt/data" "/mnt/backup" ];
    interval = "monthly";
  };

  systemd.services."btrfs-scrub-mnt-data".serviceConfig.ExecStopPost = scrubNotify "/mnt/data";
  systemd.services."btrfs-scrub-mnt-backup".serviceConfig.ExecStopPost = scrubNotify "/mnt/backup";

  # Paperless consume hot-folder on services-node, the output directory of the
  # scanner container. Automounted on first access, so a services-node that is
  # down at boot neither blocks the boot nor leaves scans on the local disk.
  fileSystems."/mnt/paperless-consume" = {
    device = "//10.1.23.224/paperless-consume";
    fsType = "cifs";
    options = [
      "guest"
      "uid=1000"
      "gid=100"
      "file_mode=0644"
      "dir_mode=0755"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.mount-timeout=15s"
    ];
  };
}

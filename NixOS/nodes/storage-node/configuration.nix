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

  # Intel UHD 770, passed through from vault (see docs/proxmox-setup.md).
  # i915 needs the GuC/HuC/DMC blobs; the qemu-guest profile ships no firmware.
  hardware.enableRedistributableFirmware = true;

  # VAAPI driver on the VM itself, only to validate the passthrough with vainfo.
  # Jellyfin brings its own driver stack in the container and just needs /dev/dri.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  environment.systemPackages = with pkgs; [
    pciutils        # lspci
    intel-gpu-tools # intel_gpu_top
    libva-utils     # vainfo
  ];

  # Data root served by NextExplorer, with the media library Jellyfin reads.
  # Lives on the VM disk until the HDDs are passed through.
  systemd.tmpfiles.rules = [
    "d /mnt/data 0755 stefan users -"
    "d /mnt/data/media 0755 stefan users -"
  ];

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

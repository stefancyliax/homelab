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

  # Data root served by NextExplorer. Lives on the VM disk until the HDDs are passed through.
  systemd.tmpfiles.rules = [
    "d /mnt/data 0755 stefan users -"
  ];
}

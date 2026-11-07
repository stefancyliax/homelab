# Intel iGPU passed through from the Proxmox host (see docs/proxmox-setup.md#igpu-passthrough).
{ pkgs, ... }:

{
  # i915 needs the GuC/HuC/DMC blobs; the qemu-guest profile ships no firmware.
  hardware.enableRedistributableFirmware = true;

  # VAAPI driver on the VM itself, only to validate the passthrough with vainfo.
  # The containers (Jellyfin, Frigate) bring their own driver stack and just need /dev/dri.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  # i915 creates the render node late in boot, and Docker gives up on a container whose
  # device is missing instead of retrying, so the container stayed down after a reboot.
  # Expose the node as a systemd device unit and start Docker only once it exists. Wants
  # (not Requires): if the passthrough is gone, Docker still starts after the device timeout.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD128", TAG+="systemd"
  '';
  systemd.services.docker = {
    wants = [ "dev-dri-renderD128.device" ];
    after = [ "dev-dri-renderD128.device" ];
  };

  environment.systemPackages = with pkgs; [
    pciutils        # lspci
    intel-gpu-tools # intel_gpu_top
    libva-utils     # vainfo
  ];
}

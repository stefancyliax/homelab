{ config, lib, pkgs, pkgs-claude, herdr, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
  ];

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nuc";

  # Bare metal: no hypervisor to talk to, so drop the guest agent from common.nix.
  services.qemuGuest.enable = lib.mkForce false;

  # CPU microcode and the firmware blobs for the iGPU and NIC. The node runs on Ethernet
  # only: Wi-Fi dropped out under USB 3 interference and broke routing next to Ethernet.
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Hardware sensors for node_exporter's hwmon collector (Host Hardware dashboard).
  # coretemp and the NVMe temperature load on their own; drivetemp adds a SATA drive.
  boot.kernelModules = [ "drivetemp" ];

  # Webcam (/dev/video*) and ESP32 serial port (/dev/ttyUSB*, /dev/ttyACM*) without sudo.
  # The tools for them (v4l-utils, esptool, ...) come from nix-shell when needed.
  users.users.stefan.extraGroups = [ "video" "dialout" ];

  # Development tools. Claude Code from its own nixos-unstable input (nixpkgs-claude): it
  # ships new versions far more often than the stable channel picks them up, and it can't
  # self-update from the Nix store. Bump with `nix flake update nixpkgs-claude`.
  environment.systemPackages = [
    pkgs.git
    pkgs-claude.claude-code
    herdr # from the herdr flake input, see flake.nix
    pkgs.lm_sensors # `sensors`, to see which chips and fans the board exposes
  ];
}

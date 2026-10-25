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

  # CPU microcode and the firmware blobs for the iGPU, NIC and Wi-Fi.
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

  # Wi-Fi, as a declarative NetworkManager profile. SSID and passphrase come from the
  # agenix env file (WIFI_SSID=..., WIFI_PSK=...) so neither lands in the public repo.
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.age.secrets."nuc-wifi".path ];
    profiles.home-wifi = {
      connection = {
        id = "home-wifi";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "$WIFI_SSID";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$WIFI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  age.secrets."nuc-wifi" = {
    file = ../../secrets/nuc-wifi.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}

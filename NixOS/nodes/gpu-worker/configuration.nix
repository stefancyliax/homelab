{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "gpu-worker";

  # Enable Tailscale
  services.tailscale.enable = true;

  # ---------------------------------------------------------------------------
  # Nvidia GPU (proprietary drivers)
  # ---------------------------------------------------------------------------
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;                   # Required for RTX 5060 Ti (Blackwell/GB206)
    nvidiaSettings = true;         # Enable nvidia-settings GUI
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable OpenGL / GPU acceleration
  hardware.graphics.enable = true;

  # ---------------------------------------------------------------------------
  # Docker + Nvidia Container Toolkit (GPU passthrough for containers)
  # ---------------------------------------------------------------------------
  hardware.nvidia-container-toolkit.enable = true;

  # ---------------------------------------------------------------------------
  # CLI & Development Tools
  # (fzf, yazi, docker-compose, curl, wget, vim already in common.nix)
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Dev & Git
    git
    gh
    neovim

    # Container tooling
    docker-buildx

    # CLI utilities
    tree
    lazydocker
    btop
    ethtool

    # GPU diagnostics
    pciutils         # lspci
    nvtopPackages.nvidia
  ];

  # Allow unfree packages (required for Nvidia drivers)
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------------------------
  # Wake-on-LAN Support
  # ---------------------------------------------------------------------------
  # Ensure WOL is enabled on the ethernet interface (assuming enp* or eth*)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="e*", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol g"
  '';
}

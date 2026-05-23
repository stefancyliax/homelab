{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    user = "stefan";
    dataDir = "/home/stefan";
    configDir = "/home/stefan/.config/syncthing";
    openDefaultPorts = true; # Open ports 22000 (TCP/UDP) and 21027 (UDP) for sync traffic
    guiAddress = "0.0.0.0:8384"; # Listen on all interfaces to allow access via Tailscale
  };

  # Restrict GUI access (port 8384) in the firewall specifically to the Tailscale interface
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8384 ];
}

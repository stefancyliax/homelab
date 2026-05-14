{ config, pkgs, ... }:

{
  # Install mosh and tmux for mobile-friendly SSH sessions
  environment.systemPackages = with pkgs; [
    mosh
    tmux
  ];


  # Open Mosh UDP ports (mosh uses UDP 60000-61000 for its session protocol)
  networking.firewall.allowedUDPPortRanges = [
    { from = 60000; to = 61000; }
  ];

  # Add Android SSH key for mobile access
  users.users.stefan.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbJ+tGvo+JKbYhSNK3YuvvBiCrbLC6fxq2YgTobErHj" #Terminus
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsYrDhPCHMHkS/e69ItNP+6fWZGCGThiNaBv70V6sYb" #Tempest
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMr58Q4LzAHLuM/fH301PRQDKOBNegXqJyGg9iNKJ6iM FOS Terminal" #FOS Terminal
  ];
}

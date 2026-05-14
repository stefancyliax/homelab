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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgniTofIH3Rr0P/ToEjoNXzkOrKu8Os/rXCYdkiP7Ksf7sW4W4Bi4Taw5dtUZxlI8qzqGmtCH+MMUmJeq+t4fRKuhEDbpdfYwyJBpUG+Jk/E5w9r2EFcxiROuzsDM9PkDTZ2hIM5HvuhcGAU5Cbijr70LunWWZz82UyI5Xhsomm0/cI9LxffnOJo1EW2DAbKCnC8fMpvcdFndPenQUuaSlq6a3o/wZlf9/iN5pbB+LkdBWnVBWEDl+TP8F4MuCAWx+1ADQGyHygB3k6ihw498eVvtp+xyvA7xM9jIBThrWeNRVnqECn3cNa6u6qa4GKp6Dp8nEZtx6aJ2yPazAx0pl9ZMHVDrUftVlozZmyjuWYTS+FCV3L/8QNCTv8ZfCf+ec5O2Q79KV4tt6V2OU8Eg/ZQQSt7tT9HtqHFLn30st6vJGhFEi7ViqvlY/IL4tDugcvvZ/Zq7XWoIkRAB5hWr3FHd8oAedbe1//cM4EjIYSl3kvySP/nhlVK3foY2xM9XzOIfhZODlgjcq3aTMxXnaANn+dK0JnV6In9PfsaNUXanP0hzfkFk11dl8nl4Nd392eaoAVbm2BGhLYuLsCf92KUNYdzhkvK11Ld929FB0ENKDL6E29Y0Cf3ik18Qbzyz6Q9eKylIFH/UyDeCfC4LSnvK/3YBavf1VDqWvQvSPRQ== FOS Terminal"
  ];
}

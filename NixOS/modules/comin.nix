{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    repositorySubdir = "NixOS";
    remotes = [{
      name = "origin";
      url = "git@github.com:stefancyliax/homelab.git";
    }];
  };

  # Configure SSH to use this deploy key when Comin reaches out to GitHub
  programs.ssh.extraConfig = ''
    Host github.com
      IdentityFile ${config.age.secrets."deploy-key".path}
      StrictHostKeyChecking accept-new
  '';

  # Decrypt the deploy key using agenix
  age.secrets."deploy-key" = {
    file = ../secrets/comin-deploy-key.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}

{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    repositorySubdir = "NixOS";
    exporter.openFirewall = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/stefancyliax/homelab.git";
      branches.main.name = "main";
      auth.access_token_path = config.age.secrets."github-pat".path;
    }];
  };

  # Decrypt the GitHub PAT using agenix
  age.secrets."github-pat" = {
    file = ../secrets/github-pat.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}

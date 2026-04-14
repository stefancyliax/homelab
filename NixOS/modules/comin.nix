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
      auth.access_token_path = config.age.secrets."comin-github-pat".path;
    }];
  };

  # Decrypt the GitHub PAT using agenix
  age.secrets."comin-github-pat" = {
    file = ../secrets/comin-github-pat.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}

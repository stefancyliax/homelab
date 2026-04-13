{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "git@github.com:stefancyliax/homelab.git";
      auth.type = "ed25519";
      auth.path = config.age.secrets."deploy-key".path;
    }];
  };

  # Decrypt the deploy key using agenix
  age.secrets."deploy-key" = {
    file = ../secrets/comin-deploy-key.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}

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
    postDeploymentCommand = toString (pkgs.writeShellScript "comin-notify" ''
        ${pkgs.curl}/bin/curl -s \
          -H "Title: Deployment status" \
          -H "Tags: white_check_mark" \
          -d "Node: $COMIN_HOSTNAME 
        Commit: $COMIN_GIT_MSG ($COMIN_GIT_REF) 
        Error: $COMIN_ERROR_MSG" \
          http://10.1.23.184:2586/homelab-deployments
    '');
  };

  # Decrypt the GitHub PAT using agenix
  age.secrets."github-pat" = {
    file = ../secrets/github-pat.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
